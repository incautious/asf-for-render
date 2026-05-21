#!/bin/bash
set -e

export ASF_IPC_PORT=${ASF_IPC_PORT:-8000}

echo "Starting ASF with IPC port ${ASF_IPC_PORT}"

/app/scripts/sync.sh boot

echo "ASF booted, starting main process"

cd /asf

dotnet ArchiSteamFarm.dll --no-restart --service &

ASF_PID=$!

echo "ASF main process started with PID ${ASF_PID}, waiting for it to exit"

wait $ASF_PID
