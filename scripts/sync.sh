#!/bin/bash
set -ex

MODE=${1:-boot}

CONFIG_DIR="/app/config"
TMP_DIR="/tmp/asf-config"

export GIT_TERMINAL_PROMPT=0
export GCM_INTERACTIVE=Never

REPOSITORY_URL="https://oauth2:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"

BRANCH="master"

git_setup () {
  git config --global --add safe.directory "$CONFIG_DIR" || true

  cd "$CONFIG_DIR"

  git config user.name "${GITHUB_USERNAME}"
  git config user.email "${GITHUB_EMAIL:-asf@render.local}"

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

    timeout 60 git \
      -c credential.helper= \
      pull --rebase origin "$BRANCH"
  else
    echo "Cloning fresh repository"

    rm -rf "$TMP_DIR"

    timeout 60 git \
      -c credential.helper= \
      clone \
      --depth 1 \
      --branch "$BRANCH" \
      "$REPOSITORY_URL" \
      "$TMP_DIR"

    find "$CONFIG_DIR" -mindepth 1 -delete || true

    cp -a "$TMP_DIR"/. "$CONFIG_DIR"/

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

  timeout 60 git \
    -c credential.helper= \
    pull --rebase origin "$BRANCH" || true

  echo "Pushing changes to repository"

  timeout 60 git \
    -c credential.helper= \
    push origin "$BRANCH" || true

  echo "Push sync completed"
}

watch_sync () {
  echo "Starting watch sync process"

  while true; do
    inotifywait \
      -r \
      -e modify,create,delete,move \
      "$CONFIG_DIR"

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
