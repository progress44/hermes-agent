#!/bin/bash

set -euo pipefail

INSTALL_DIR="/opt/hermes"
HERMES_HOME="${HERMES_HOME:-/opt/hermes-home}"
HOME_DIR="${HOME:-/home/node}"
HERMES_ENABLE_GATEWAY="${HERMES_ENABLE_GATEWAY:-0}"
HERMES_ENABLE_API_SERVER="${HERMES_ENABLE_API_SERVER:-0}"
HERMES_GATEWAY_RESTART_DELAY_SECONDS="${HERMES_GATEWAY_RESTART_DELAY_SECONDS:-30}"

export HERMES_HOME
export HOME="$HOME_DIR"
export HERMES_WEB_DIST="${HERMES_WEB_DIST:-$INSTALL_DIR/hermes_cli/web_dist}"
export HERMES_TUI_DIR="${HERMES_TUI_DIR:-$INSTALL_DIR/ui-tui}"
export HERMES_PYTHON="${HERMES_PYTHON:-$INSTALL_DIR/.venv/bin/python}"
export PATH="$INSTALL_DIR/.venv/bin:$HOME/.local/bin:$PATH"
export API_SERVER_ENABLED="$HERMES_ENABLE_API_SERVER"

warn() {
    echo "hermes-olares: $*" >&2
}

ensure_dir() {
    local path="$1"
    if mkdir -p "$path" 2>/dev/null; then
        return 0
    fi
    warn "could not create $path; verify the mounted Hermes volumes are writable by UID/GID 1000"
    return 1
}

if [ "$#" -eq 0 ]; then
    set -- workspace
fi

role="$1"

copy_if_missing() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ]; then
        return 0
    fi
    if [ ! -f "$src" ]; then
        warn "missing default file $src"
        return 1
    fi
    if ! ensure_dir "$(dirname "$dst")"; then
        return 1
    fi
    if ! cp "$src" "$dst" 2>/dev/null; then
        warn "could not initialize $dst"
        return 1
    fi
}

ensure_dir "$HERMES_HOME"
ensure_dir "$HOME"
ensure_dir "$HOME/.local/bin" || true
ensure_dir "$HOME/.npm-global/bin" || true

for subdir in cron hooks logs memories plans sessions skills skins workspace; do
    ensure_dir "$HERMES_HOME/$subdir" || true
done

copy_if_missing "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env" || true
copy_if_missing "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml" || true
copy_if_missing "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md" || true

if [ "$role" = "dashboard" ] && [ -d "$INSTALL_DIR/skills" ] && [ -w "$HERMES_HOME" ]; then
    "$HERMES_PYTHON" "$INSTALL_DIR/tools/skills_sync.py" >/dev/null 2>&1 || \
        warn "bundled skill sync failed; continuing with baked-in skills"
fi

run_workspace() {
    if [ "$#" -gt 0 ]; then
        exec "$@"
    fi
    exec sleep infinity
}

run_dashboard() {
    exec hermes dashboard --host 0.0.0.0 --port "${HERMES_DASHBOARD_PORT:-9119}" --no-open --insecure --tui "$@"
}

run_gateway() {
    while true; do
        warn "starting gateway runtime"
        hermes gateway run --replace "$@" || true
        warn "gateway exited; retrying in ${HERMES_GATEWAY_RESTART_DELAY_SECONDS}s"
        sleep "${HERMES_GATEWAY_RESTART_DELAY_SECONDS}"
    done
}

shift || true

case "$role" in
    workspace)
        run_workspace "$@"
        ;;
    dashboard)
        run_dashboard "$@"
        ;;
    gateway)
        run_gateway "$@"
        ;;
    *)
        exec "$role" "$@"
        ;;
esac
