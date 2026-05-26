#!/bin/bash
set -e

BRANCH="$(git rev-parse --abbrev-ref HEAD)"

git add -A

MESSAGE="$(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g')"

git commit -a -m "$MESSAGE" || true

git push origin "$BRANCH"

echo "Files committed and pushed to ${BRANCH}!"
