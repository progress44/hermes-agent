# Hermes Agent for Olares

This package deploys a dashboard-first Hermes Agent instance on Olares using:

- `ghcr.io/progress44/hermes-agent-olares:1.0.0`

The app exposes:

- Hermes web dashboard at `http://hermesagent-svc:9119`
- Embedded browser chat powered by `hermes --tui`

## Runtime defaults

- `HERMES_ENABLE_GATEWAY=0`
- `HERMES_ENABLE_API_SERVER=0`

The package does not require install-time provider secrets. Configure model
provider keys after install from the dashboard or by editing `~/.hermes/.env`
inside the mounted app-data directory.

## Persistence

All Hermes runtime state is mounted at `/opt/data` and persisted under
`userspace.appData/hermes-home`, including:

- `.env`
- `config.yaml`
- `sessions/`
- `logs/`
- `skills/`
- `memories/`
- `plans/`

## Optional gateway mode

To enable the background messaging gateway, set:

- `app.gatewayEnabled=true`

The gateway only remains active when at least one messaging platform is
configured in `/opt/data/.env` or `/opt/data/config.yaml`.

If you also want the OpenAI-compatible API server inside the gateway process,
set:

- `app.apiServerEnabled=true`

## Validation

```bash
helm lint olares/hermesagent
helm template hermesagent olares/hermesagent
helm package olares/hermesagent
```

## Operational note

The container runs as UID/GID `1000`. If Olares creates the mounted host path
as `root:root`, pre-create and `chown -R 1000:1000` the `hermes-home`
directory on the node before the final install.
