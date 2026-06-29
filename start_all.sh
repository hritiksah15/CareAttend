#!/usr/bin/env bash
# Launch the whole Care Attend stack: backend API + website, Flutter app, DB GUI.
# Usage: ./start_all.sh        (stop with ./start_all.sh stop)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/development/flutter/bin:$PATH"

BACKEND_SESSION="careattend_backend"
PGWEB_SESSION="careattend_pgweb"
FLUTTER_SESSION="careattend_flutter"
STALE_STATIC_SESSION="careattend_static_8092"
PID_DIR="${TMPDIR:-/tmp}"
pidfile() { echo "${PID_DIR%/}/careattend_$1.pid"; }

free_port() {
  local pids
  pids="$(lsof -ti :"$1" 2>/dev/null || true)"
  [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
}

# Tear a service down completely: quit its screen session AND kill the supervisor
# process group (recorded in the pidfile) so the restart loop cannot resurrect a
# child after we free the port. Belt-and-suspenders across screen / setsid modes.
stop_session() {
  local name="$1" pf p
  command -v screen >/dev/null 2>&1 && screen -S "$name" -X quit >/dev/null 2>&1 || true
  pf="$(pidfile "$name")"
  if [ -f "$pf" ]; then
    p="$(cat "$pf" 2>/dev/null || true)"
    if [ -n "$p" ]; then
      kill -TERM "-$p" 2>/dev/null || kill -TERM "$p" 2>/dev/null || true
      sleep 0.3
      kill -KILL "-$p" 2>/dev/null || kill -KILL "$p" 2>/dev/null || true
    fi
    rm -f "$pf"
  fi
}

# Supervisor: restart the service command on exit with capped backoff, so a crash
# or a transient port hiccup self-heals instead of leaving a dead port. The loop
# records its own PID (a process-group leader) for clean teardown.
# NOTE: this does NOT hot-reload edited code — re-run ./start_all.sh after
# changing backend code to pick it up.
run_persistent() {
  local name="$1" log="$2" command="$3" pf
  pf="$(pidfile "$name")"
  : > "$log"
  stop_session "$name"
  local loop="echo \$\$ > $(printf '%q' "$pf"); delay=2; while true; do $command; ec=\$?; echo \"[supervisor] $name exited (code \$ec); restart in \${delay}s\"; sleep \$delay; [ \$delay -lt 30 ] && delay=\$(( delay * 2 )); done"
  if command -v screen >/dev/null 2>&1; then
    screen -dmS "$name" bash -lc "$loop >$(printf '%q' "$log") 2>&1"
  else
    setsid bash -lc "$loop" >"$log" 2>&1 < /dev/null &
  fi
}

wait_for_http() {
  local url="$1" needle="$2" attempts="$3"
  for _ in $(seq 1 "$attempts"); do
    curl -s -m2 "$url" 2>/dev/null | grep -q "$needle" && return 0
    sleep 1
  done
  return 1
}

wait_for_port() {
  local port="$1" attempts="$2"
  for _ in $(seq 1 "$attempts"); do
    lsof -ti :"$port" >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
}

if [ "${1:-}" = "stop" ]; then
  echo "Stopping stack..."
  stop_session "$BACKEND_SESSION"
  stop_session "$PGWEB_SESSION"
  stop_session "$FLUTTER_SESSION"
  stop_session "$STALE_STATIC_SESSION"
  for p in 5000 8090 8091 8092 8081; do free_port "$p"; done
  echo "Stopped (ports 5000/8090/8091/8092/8081 freed)."
  exit 0
fi

echo "── 1/3  Backend + website (:5000)"
stop_session "$BACKEND_SESSION"
free_port 5000
run_persistent "$BACKEND_SESSION" /tmp/careattend.log "cd $(printf '%q' "$ROOT")/backend && ./run.sh"
if wait_for_http "http://127.0.0.1:5000/health" '"status":"ok"' 45; then
  echo "   ✓ http://127.0.0.1:5000"
else
  echo "   ! backend did not become healthy; see /tmp/careattend.log"
fi

echo "── 2/3  DB browser pgweb (:8081)"
stop_session "$PGWEB_SESSION"
free_port 8081
if command -v pgweb >/dev/null; then
  run_persistent "$PGWEB_SESSION" /tmp/pgweb.log 'pgweb --url "postgresql://localhost:5432/careattend?sslmode=disable" --listen 8081 --bind 127.0.0.1'
  if wait_for_port 8081 15; then
    echo "   ✓ http://localhost:8081"
  else
    echo "   ! pgweb did not start; see /tmp/pgweb.log"
  fi
else
  echo "   ! pgweb not installed (brew install pgweb)"
fi

echo "── 3/3  Flutter web app (:8090)"
stop_session "$FLUTTER_SESSION"
stop_session "$STALE_STATIC_SESSION"
free_port 8090
free_port 8091
free_port 8092
if command -v flutter >/dev/null; then
  # Build from current source on every launch and disable the local PWA service
  # worker. This avoids Chrome serving an older cached Flutter app after a
  # previous debug/release run.
  run_persistent "$FLUTTER_SESSION" /tmp/flutter_app.log "cd $(printf '%q' "$ROOT")/care_attend_app && export PATH=$(printf '%q' "$HOME")/development/flutter/bin:\$PATH && flutter clean >/dev/null && flutter pub get >/dev/null && flutter build web --pwa-strategy=none --dart-define=API_BASE=http://127.0.0.1:5000 && cd build/web && python3 -m http.server 8090 --bind 127.0.0.1"
  if wait_for_port 8090 180; then
    echo "   ✓ http://127.0.0.1:8090"
  else
    echo "   ! Flutter build/server still starting or failed; see /tmp/flutter_app.log"
  fi
else
  echo "   ! flutter not on PATH (export PATH=\"\$HOME/development/flutter/bin:\$PATH\")"
fi

echo ""
echo "All started. Logs: /tmp/careattend.log  /tmp/pgweb.log  /tmp/flutter_app.log"
command -v screen >/dev/null 2>&1 && echo "Persistent sessions: $BACKEND_SESSION  $PGWEB_SESSION  $FLUTTER_SESSION"
echo "Stop everything: ./start_all.sh stop"
