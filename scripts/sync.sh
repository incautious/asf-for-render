#!/bin/bash
set -ex

MODE=${1:-boot}

CONFIG_DIR="/app/config"
TMP_CLONE="/tmp/asf-config"
REPOSITORY_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"
BRANCH="master"

boot_sync () {
  echo "Starting boot sync process"

  rm -rf "$TMP_CLONE"

  git clone --depth 1 --branch "$BRANCH" "$REPOSITORY_URL" "$TMP_CLONE" || { echo "Git clone failed"; exit 1; }

  mkdir -p "$CONFIG_DIR"

  echo "Copying configs to $CONFIG_DIR, preserving .gitkeep"

  rsync -a --delete \
    --exclude '.git' \
    "$TMP_CLONE"/ "$CONFIG_DIR"/

  echo "Boot sync completed"
}

case "$MODE" in
  boot)
    boot_sync
    ;;
  *)
    echo "Unknown mode: $MODE"
    exit 1
    ;;
esac
