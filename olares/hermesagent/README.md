# Hermes Agent for Olares

This package deploys a `clawdbot`-style Hermes Agent on Olares using:

- `beclab/nousresearch-hermes-agent:v2026.5.7`

The app exposes two entrances:

- `Hermes CLI`
- `Dashboard`

Internally the package uses:

- a long-lived workspace container for terminal sessions
- a dashboard sidecar for the Hermes web UI and embedded TUI chat
- a best-effort gateway sidecar for messaging/runtime services
- a terminal helper deployment

## Runtime defaults

- Control UI remains available even when the gateway sidecar is not yet configured
- gateway sidecar retries in the background, but Hermes may still report
  `gateway_state: stopped` until messaging platforms are configured
- `hermes gateway restart` does not restart the containerized gateway directly.
  Use `touch /opt/data/.gateway-restart-requested` from inside the workspace to
  request a gateway restart.
- API server remains disabled by default

The package does not require install-time provider secrets. Configure model
provider keys after install from the dashboard or by editing
`/opt/data/.env` inside the mounted app-data volume.

## Persistence

Hermes runtime state is persisted under:

- `userspace.appData` mounted at `/opt/data`

Key persisted files and directories include:

- `.env`
- `config.yaml`
- `sessions/`
- `logs/`
- `skills/`
- `memories/`
- `plans/`

## Optional filesystem access

At install time, Olares can expose additional host paths:

- `ALLOW_HOME_DIR_ACCESS=true`
- `ALLOW_EXTERNAL_DIR_ACCESS=true`

These mounts are absent by default.

## Validation

```bash
helm lint olares/hermesagent
helm template hermesagent olares/hermesagent
helm package olares/hermesagent
```

## Operational note

The chart includes a root init container to prepare and chown the persisted
Hermes data directory before the main containers start.
