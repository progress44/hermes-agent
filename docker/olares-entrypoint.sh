#!/bin/bash

set -euo pipefail

INSTALL_DIR="/opt/hermes"
HERMES_HOME="${HERMES_HOME:-/opt/data}"
HERMES_ENABLE_GATEWAY="${HERMES_ENABLE_GATEWAY:-0}"
HERMES_ENABLE_API_SERVER="${HERMES_ENABLE_API_SERVER:-0}"

export HERMES_HOME
export HOME="${HOME:-$HERMES_HOME/home}"
export HERMES_WEB_DIST="${HERMES_WEB_DIST:-$INSTALL_DIR/hermes_cli/web_dist}"
export HERMES_TUI_DIR="${HERMES_TUI_DIR:-$INSTALL_DIR/ui-tui}"
export HERMES_PYTHON="${HERMES_PYTHON:-$INSTALL_DIR/.venv/bin/python}"
export PATH="$INSTALL_DIR/.venv/bin:$PATH"
export API_SERVER_ENABLED="$HERMES_ENABLE_API_SERVER"

warn() {
    echo "hermes-olares: $*" >&2
}

ensure_dir() {
    local path="$1"
    if mkdir -p "$path" 2>/dev/null; then
        return 0
    fi
    warn "could not create $path; verify /opt/data is writable by UID/GID 1000"
    return 1
}

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

for subdir in cron hooks logs memories plans sessions skills skins workspace; do
    ensure_dir "$HERMES_HOME/$subdir" || true
done

copy_if_missing "$INSTALL_DIR/.env.example" "$HERMES_HOME/.env" || true
copy_if_missing "$INSTALL_DIR/cli-config.yaml.example" "$HERMES_HOME/config.yaml" || true
copy_if_missing "$INSTALL_DIR/docker/SOUL.md" "$HERMES_HOME/SOUL.md" || true

if [ -d "$INSTALL_DIR/skills" ] && [ -w "$HERMES_HOME" ]; then
    "$HERMES_PYTHON" "$INSTALL_DIR/tools/skills_sync.py" >/dev/null 2>&1 || \
        warn "bundled skill sync failed; continuing with baked-in skills"
fi

if [[ "$HERMES_ENABLE_GATEWAY" =~ ^(1|true|TRUE|yes|YES)$ ]]; then
    warn "starting background gateway"
    hermes gateway run --replace &
fi

exec hermes dashboard --host 0.0.0.0 --port 9119 --no-open --insecure --tui
