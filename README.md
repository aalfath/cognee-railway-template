[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/cognee?utm_medium=integration&utm_source=button&utm_campaign=cognee)

# Cognee on Railway

This repo builds the Cognee service of the [Cognee Railway template](https://railway.com/deploy/cognee). [Cognee](https://github.com/topoteretes/cognee) is an open-source AI memory engine: it turns documents and conversations into a knowledge graph plus vector embeddings that your agents can search.

## What the template deploys

| Service | Source | State |
|---|---|---|
| **Cognee** (public) | this repo: `cognee/cognee:1.6.8` pinned by digest, plus a small start script | volume on `/cognee-storage` (raw files, per-dataset graph files, caches) |
| **Postgres** | Railway's Postgres (ships pgvector) | volume; users, API keys, datasets, embeddings |

- Cognee **1.6.8** (`cognee/cognee:1.6.8@sha256:808773bb4b35883f2ff3d4d72f32c58e5230e97df7ea09d9a6f73bdef9bddc8e`).
- Health check: `GET /health` (checks Postgres, pgvector, the graph store and file storage).
- Multi-user mode with authentication on: every API call needs a login token or an API key, and each user's datasets are isolated.
- Open self-registration (`POST /api/v1/auth/register`) answers 403 unless you set `ALLOW_SIGNUP=true` on the Cognee service.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `LLM_API_KEY` | prompt | Your OpenAI API key (LLM and embeddings). For another provider, also set `LLM_PROVIDER`, `LLM_MODEL` and the `EMBEDDING_*` variables (see Cognee's `.env.template`). |
| `DEFAULT_USER_EMAIL` | `default_user@example.com` | Login of the built-in admin. Applied on the first boot only. |
| `DEFAULT_USER_PASSWORD` | generated | Password of the built-in admin, set once on the first boot. Change it later with `PATCH /api/v1/users/me`. |
| `FASTAPI_USERS_*_SECRET` | generated | Sign login, reset and verification tokens, so logins survive restarts. |
| `DB_*` | references to Postgres | Relational and vector store. |
| `PORT` | `8000` | Port gunicorn listens on. |

The start script fixes the rest: Postgres + pgvector, the embedded graph store on the volume, `ENV=prod`, hashed API keys, raw Cypher search off, secure cookies.

## After deploying

1. Open `https://YOUR-DOMAIN/docs` for the interactive API.
2. Log in: `curl -X POST https://YOUR-DOMAIN/api/v1/auth/login -d username=default_user@example.com -d password=DEFAULT_USER_PASSWORD` (the password is in the Cognee service's variables).
3. Create an API key with the returned token: `curl -X POST https://YOUR-DOMAIN/api/v1/auth/api-keys -H "Authorization: Bearer TOKEN" -H 'Content-Type: application/json' -d '{"name":"agents"}'`. It is shown once.
4. Use the key as the `X-Api-Key` header, for example from the Python SDK, or from the Cognee MCP server running on your own machine in API mode: `cognee-mcp --api-url https://YOUR-DOMAIN --api-token YOUR-KEY --api-auth-scheme x-api-key`.

## Updates

Railway tells everyone who deployed this template when `main` changes. A version bump changes the `FROM` line in `Dockerfile` (tag and digest) and adds an entry to `CHANGELOG.md`, with breaking changes first. Read the changelog, back up Postgres, then apply the update from your project. Cognee runs its database migrations on start.

## Layout

- `Dockerfile`: pins the upstream image and adds the wrapper.
- `wrapper/start.sh`: fixed settings, volume ownership, then the upstream entrypoint as the image's non-root user.
- `wrapper/railway_guard.py`: closes the self-registration route unless `ALLOW_SIGNUP=true`.

Cognee is Apache-2.0, by Topoteretes. This wrapper is not affiliated with them.
