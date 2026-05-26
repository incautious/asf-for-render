#!/bin/bash
set -e

export ASF_IPC_PORT=${ASF_IPC_PORT:-8000}

cleanup_done=0

cleanup () {
  if [ "$cleanup_done" -eq 1 ]; then
    return
  fi

  cleanup_done=1

  echo "Stopping ASF and config watch processes"

  /app/scripts/sync.sh push || true

  kill $WATCH_PID 2>/dev/null || true
  kill $ASF_PID 2>/dev/null || true
  kill $HEALTH_PID 2>/dev/null || true

  wait $ASF_PID 2>/dev/null || true
}

trap cleanup SIGTERM SIGINT EXIT

echo "Starting temporary healthcheck server on port ${ASF_IPC_PORT}"

(
while true; do
  printf "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p "${ASF_IPC_PORT}"
done
) >/dev/null 2>&1 &

HEALTH_PID=$!

echo "Running boot sync"

/app/scripts/sync.sh boot

echo "Starting config watch process"

/app/scripts/sync.sh watch &

WATCH_PID=$!

echo "Starting ASF"

cd /asf

dotnet ArchiSteamFarm.dll --no-restart --service &

ASF_PID=$!

echo "ASF started with PID ${ASF_PID}"

sleep 10

kill $HEALTH_PID 2>/dev/null || true

wait $ASF_PID || true
