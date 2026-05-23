#!/bin/bash
set -ex

MODE=${1:-boot}

CONFIG_DIR="/app/config"

REPOSITORY_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"
BRANCH="master"

git_setup () {
  git config --global --add safe.directory "$CONFIG_DIR" || true

  cd "$CONFIG_DIR"

  git config user.name "${GITHUB_USERNAME}"
  git config user.email "${GITHUB_EMAIL}"

  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REPOSITORY_URL"
  else
    git remote add origin "$REPOSITORY_URL"
  fi
}

boot_sync () {
  echo "Starting boot sync process"

  mkdir -p "$CONFIG_DIR"

  if [ -d "$CONFIG_DIR/.git" ]; then
    echo "Existing git repository found in $CONFIG_DIR"

    cd "$CONFIG_DIR"

    git_setup

    git reset --hard

    git pull --rebase origin "$BRANCH"
  else
    echo "Cloning fresh repository to $CONFIG_DIR"

    rm -rf "$CONFIG_DIR"

    git clone \
      --depth 1 \
      --branch "$BRANCH" \
      "$REPOSITORY_URL" \
      "$CONFIG_DIR"

    cd "$CONFIG_DIR"

    git_setup
  fi

  echo "Boot sync completed"
}

push_sync () {
  echo "Starting push sync process"

  cd "$CONFIG_DIR"

  git_setup

  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to push"

    return 0
  fi

  echo "Changes detected, preparing commit"

  git add -A

  git commit -m "auto sync $(date '+%Y-%m-%d %H:%M:%S')" || true

  echo "Pulling latest changes from repository to avoid conflicts"

  git pull --rebase origin "$BRANCH" || true

  echo "Pushing changes to repository"

  git push origin "$BRANCH" || true

  echo "Push sync completed"
}

watch_sync () {
  echo "Starting watch sync process"

  while true; do
    inotifywait -r -e modify,create,delete,move "$CONFIG_DIR"

    sleep 2

    push_sync || true
  done
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
