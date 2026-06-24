#!/usr/bin/env bash
# Repeatable WCAG 2.2 accessibility scan (NFR-03).
# Boots the app on a throwaway SQLite database (never PostgreSQL), seeds a staff
# user, runs the axe-core/Playwright scan, then tears the server down.
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"

PORT="${A11Y_PORT:-5055}"
USER="${A11Y_USER:-bench}"
PASS="${A11Y_PASS:-Password123!}"
DB="$(mktemp -t careattend_a11y.XXXXXX.sqlite)"

export DATABASE_URL="sqlite:///$DB"
export PORT FLASK_DEBUG=0
export A11Y_URL="http://127.0.0.1:$PORT" A11Y_USER="$USER" A11Y_PASS="$PASS"

# Activate the project venv if present.
[ -f "$ROOT/.venv/bin/activate" ] && source "$ROOT/.venv/bin/activate"

# Boot the server (exec so $SRV is the python pid, not the subshell).
( cd "$ROOT/backend" && exec python app.py >/tmp/careattend_a11y_server.log 2>&1 ) &
SRV=$!
cleanup() { kill "$SRV" 2>/dev/null || true; rm -f "$DB"; }
trap cleanup EXIT

# Wait for the server to come up.
for _ in $(seq 1 40); do
  curl -sf -o /dev/null "$A11Y_URL/" && break
  sleep 0.5
done
curl -sf -o /dev/null "$A11Y_URL/" || { echo "ERROR: server did not start"; cat /tmp/careattend_a11y_server.log; exit 1; }

# Seed a staff user: register via the API, then promote in the DB.
curl -s -X POST "$A11Y_URL/auth/register" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"email\":\"$USER@nhs.uk\",\"password\":\"$PASS\"}" >/dev/null || true
python - "$DB" "$USER" <<'PY'
import sqlite3, sys
db, user = sys.argv[1], sys.argv[2]
c = sqlite3.connect(db)
c.execute("UPDATE users SET role='staff' WHERE username=?", (user,))
c.commit()
c.close()
PY

# Run the scan (exits non-zero if any violations remain).
node axe_scan.mjs
