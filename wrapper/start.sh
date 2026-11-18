#!/bin/sh
# Railway start script for Cognee. Fixed settings live here, so the template
# only carries references, secrets and the values a deployer may change.
set -eu

STORAGE=/cognee-storage
export SYSTEM_ROOT_DIRECTORY="${SYSTEM_ROOT_DIRECTORY:-$STORAGE/system}"
export DATA_ROOT_DIRECTORY="${DATA_ROOT_DIRECTORY:-$STORAGE/data}"

# Railway sets PORT. Bind dual stack so the private network (IPv6) and the
# health check both reach gunicorn.
export HTTP_PORT="${PORT:-${HTTP_PORT:-8000}}"
export BIND_ADDRESS="${BIND_ADDRESS:-[::]}"
export ENV="${ENV:-prod}"

# Postgres for users, datasets and pipeline state; pgvector (same Postgres) for embeddings.
export DB_PROVIDER="${DB_PROVIDER:-postgres}"
export VECTOR_DB_PROVIDER="${VECTOR_DB_PROVIDER:-pgvector}"
export VECTOR_DB_HOST="${VECTOR_DB_HOST:-${DB_HOST:-}}"
export VECTOR_DB_PORT="${VECTOR_DB_PORT:-${DB_PORT:-5432}}"
export VECTOR_DB_NAME="${VECTOR_DB_NAME:-${DB_NAME:-}}"
export VECTOR_DB_USERNAME="${VECTOR_DB_USERNAME:-${DB_USERNAME:-}}"
export VECTOR_DB_PASSWORD="${VECTOR_DB_PASSWORD:-${DB_PASSWORD:-}}"
# Graph: upstream's embedded Ladybug (Kuzu) files under $SYSTEM_ROOT_DIRECTORY.
export GRAPH_DATABASE_PROVIDER="${GRAPH_DATABASE_PROVIDER:-kuzu}"

# Public deployment: every endpoint needs a login or an API key, per-user datasets.
export ENABLE_BACKEND_ACCESS_CONTROL="${ENABLE_BACKEND_ACCESS_CONTROL:-true}"
export REQUIRE_AUTHENTICATION="${REQUIRE_AUTHENTICATION:-true}"
export HASH_API_KEY="${HASH_API_KEY:-true}"
export ALLOW_CYPHER_QUERY="${ALLOW_CYPHER_QUERY:-false}"
export AUTH_TOKEN_COOKIE_SECURE="${AUTH_TOKEN_COOKIE_SECURE:-true}"
export LITELLM_LOG="${LITELLM_LOG:-ERROR}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"
# Local fallback models (only used without an API key) cache on the volume.
export HF_HOME="${HF_HOME:-$STORAGE/huggingface}"

if [ -z "${LLM_API_KEY:-}" ]; then
  echo "railway-start: LLM_API_KEY is empty; Cognee falls back to small local models." >&2
fi

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$SYSTEM_ROOT_DIRECTORY" "$DATA_ROOT_DIRECTORY" "$HF_HOME"
  # A new Railway volume is owned by root; the app runs as uid 1000.
  if [ "$(stat -c %u "$STORAGE")" != "1000" ] || [ "$(stat -c %u "$SYSTEM_ROOT_DIRECTORY")" != "1000" ]; then
    chown -R 1000:1000 "$STORAGE"
  fi
  chown 1000:1000 "$SYSTEM_ROOT_DIRECTORY" "$DATA_ROOT_DIRECTORY" "$HF_HOME" "$STORAGE"
  exec setpriv --reuid=1000 --regid=1000 --init-groups /app/entrypoint.sh "$@"
fi

exec /app/entrypoint.sh "$@"
