#!/usr/bin/env bash
# CareAttend launcher — starts the database and backend together.
# Usage: ./run.sh            (from the backend/ directory or anywhere)
set -euo pipefail
cd "$(dirname "$0")"

export DATABASE_URL="${DATABASE_URL:-postgresql+psycopg://localhost:5432/careattend}"
export PORT="${PORT:-5000}"
export FLASK_APP=app

# 1. Activate the virtualenv if present.
[ -f ../.venv/bin/activate ] && source ../.venv/bin/activate

# 1b. Persistent SECRET_KEY so sessions/signed cookies survive restarts (dev).
# Generated once into a gitignored file; production should set SECRET_KEY in the
# environment instead. Without this, app.py falls back to a per-process random
# key and every restart silently invalidates all logins.
if [ -z "${SECRET_KEY:-}" ]; then
  KEY_FILE="$(dirname "$0")/.secret_key"
  if [ ! -s "$KEY_FILE" ]; then
    (python -c 'import secrets; print(secrets.token_hex(32))' 2>/dev/null \
      || openssl rand -hex 32) > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
  fi
  SECRET_KEY="$(cat "$KEY_FILE")"
  export SECRET_KEY
fi

# 2. Ensure PostgreSQL is running (Homebrew service).
if ! pg_isready -q 2>/dev/null; then
  echo "PostgreSQL not running — starting it..."
  brew services start postgresql@16 >/dev/null 2>&1 || true
  for _ in $(seq 1 20); do pg_isready -q && break; sleep 0.5; done
fi
pg_isready -q || { echo "ERROR: PostgreSQL did not come up."; exit 1; }

# 3. Ensure the database exists.
if ! psql -lqt 2>/dev/null | cut -d'|' -f1 | grep -qw careattend; then
  echo "Creating database 'careattend'..."
  createdb careattend
fi

# 4. Free the port if a stale process is holding it.
if lsof -ti :"$PORT" >/dev/null 2>&1; then
  echo "Port $PORT busy — freeing it..."
  lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true
  sleep 1
fi

# 5. Apply migrations (app.py also runs create_all as a fallback).
flask db upgrade >/dev/null 2>&1 || echo "Note: migrations skipped (schema ensured at startup)."

# 6. Start the backend.
echo "Starting CareAttend backend on http://127.0.0.1:$PORT"
exec python app.py
