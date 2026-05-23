#!/bin/bash
set -e

export ASF_IPC_PORT=${ASF_IPC_PORT:-1242}

echo "Starting ASF with IPC port ${ASF_IPC_PORT}"

echo "Running boot sync"

/app/scripts/sync.sh boot

echo "Starting config watch process"

/app/scripts/sync.sh watch &

WATCH_PID=$!

echo "Starting ASF main process"

cd /asf

dotnet ArchiSteamFarm.dll --no-restart --service &

ASF_PID=$!

echo "ASF started with PID ${ASF_PID}"

cleanup () {
  echo "Stopping ASF and config watch processes"

  /app/scripts/sync.sh push || true

  kill $WATCH_PID 2>/dev/null || true

  kill $ASF_PID 2>/dev/null || true
  wait $ASF_PID 2>/dev/null || true
}

trap cleanup SIGTERM SIGINT

wait $ASF_PID || true

cleanup
