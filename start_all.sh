#!/usr/bin/env bash
# Launch the whole Care Attend stack: backend API + website, Flutter app, DB GUI.
# Usage: ./start_all.sh        (stop with ./start_all.sh stop)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/development/flutter/bin:$PATH"

free_port() { lsof -ti :"$1" 2>/dev/null | xargs kill -9 2>/dev/null; }

if [ "${1:-}" = "stop" ]; then
  echo "Stopping stack..."
  for p in 5000 8090 8081; do free_port "$p"; done
  echo "Stopped (ports 5000/8090/8081 freed)."
  exit 0
fi

echo "── 1/3  Backend + website (:5000)"
free_port 5000
( cd "$ROOT/backend" && nohup ./run.sh >/tmp/careattend.log 2>&1 & )
for i in $(seq 1 30); do
  curl -s -m2 localhost:5000/health 2>/dev/null | grep -q '"status":"ok"' && { echo "   ✓ http://127.0.0.1:5000"; break; }
  sleep 1
done

echo "── 2/3  DB browser pgweb (:8081)"
free_port 8081
if command -v pgweb >/dev/null; then
  nohup pgweb --url "postgresql://localhost:5432/careattend?sslmode=disable" --listen 8081 --bind 127.0.0.1 >/tmp/pgweb.log 2>&1 &
  sleep 2; echo "   ✓ http://localhost:8081"
else
  echo "   ! pgweb not installed (brew install pgweb)"
fi

echo "── 3/3  Flutter app on Chrome (:8090)"
free_port 8090
if command -v flutter >/dev/null; then
  ( cd "$ROOT/care_attend_app" && nohup flutter run -d chrome --web-port=8090 >/tmp/flutter_app.log 2>&1 & )
  echo "   ✓ http://localhost:8090  (Chrome opens after ~30-60s build)"
else
  echo "   ! flutter not on PATH (export PATH=\"\$HOME/development/flutter/bin:\$PATH\")"
fi

echo ""
echo "All started. Logs: /tmp/careattend.log  /tmp/pgweb.log  /tmp/flutter_app.log"
echo "Stop everything: ./start_all.sh stop"
