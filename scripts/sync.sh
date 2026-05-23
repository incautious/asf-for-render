#!/bin/bash
set -ex

MODE=${1:-boot}

CONFIG_DIR="/app/config"
TMP_CLONE="/tmp/asf-config"
REPOSITORY_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"
BRANCH="master"

git_setup () {
  git config --global --add safe.directory "$CONFIG_DIR" || true

  cd "$CONFIG_DIR"

  git config user.name "${GITHUB_USERNAME}"
  git config user.email "${GITHUB_EMAIL}" || true

  git remote remove origin 2>/dev/null || true
  git remote add origin "$REPOSITORY_URL" 2>/dev/null || true
}

boot_sync () {
  echo "Starting boot sync process"

  rm -rf "$TMP_CLONE"

  git clone \
    --depth 1 \
    --branch "$BRANCH" \
    "$REPOSITORY_URL" \
    "$TMP_CLONE" || { echo "Git clone failed"; exit 1; }

  mkdir -p "$CONFIG_DIR"

  echo "Copying configs to $CONFIG_DIR, preserving .gitkeep"

  rsync -a --delete \
    --exclude '.git' \
    "$TMP_CLONE"/ "$CONFIG_DIR"/

  cd "$CONFIG_DIR"

  git init 2>/dev/null || true

  git_setup

  echo "Boot sync completed"
}

push_sync () {
  echo "Starting push sync process"

  git_setup

  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to push"

    exit 0
  fi

  echo "Changes detected, pushing to repository"

  git add -A || true
  git commit -a -m "$(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g')" || true
  git push "$REPOSITORY_URL" "$BRANCH" || true

  echo "Push sync completed"
}

watch_sync () {
  echo "Starting watch sync process"

  while true; do
    inotifywait -r -e modify,create,delete,move "$CONFIG_DIR"

    sleep 2

    push_sync || true
  done

  echo "Watch sync process exited"
}

case "$MODE" in
  boot)
    boot_sync
    ;;
  push)
    push_sync
    ;;
  watch)
    watch_sync
    ;;
  *)
    echo "Unknown mode ($MODE)"
    exit 1
    ;;
esac
