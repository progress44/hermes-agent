# Hermes Agent for Olares

This package deploys a `clawdbot`-style Hermes Agent on Olares using:

- `ghcr.io/progress44/hermes-agent-olares:1.2.0`

The app exposes two entrances:

- `Hermes CLI`
- `Control UI`

Internally the package uses:

- a long-lived workspace container for terminal sessions
- a dashboard sidecar for the Hermes web UI and embedded TUI chat
- a best-effort gateway sidecar for messaging/runtime services
- a terminal helper deployment
- a proxy ingress deployment

## Runtime defaults

- Control UI remains available even when the gateway sidecar is not yet configured
- gateway sidecar retries in the background, but Hermes may still report
  `gateway_state: stopped` until messaging platforms are configured
- API server remains disabled by default

The package does not require install-time provider secrets. Configure model
provider keys after install from the dashboard or by editing
`/opt/hermes-home/.env` inside the mounted app-data volume.

## Persistence

Hermes runtime state is split into two persistent roots:

- `userspace.appData/config` mounted at `/opt/hermes-home`
- `userspace.appData/node` mounted at `/home/node`

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

The container runs as UID/GID `1000`. If Olares creates the mounted host path
as `root:root`, the chart includes a root init container to create and chown
the Hermes data directories before the main containers start.
