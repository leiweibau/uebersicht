#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

cd "$ROOT_DIR"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required to build the server release" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to build the server release" >&2
  exit 1
fi

needs_install=0

if [ ! -x node_modules/.bin/browserify ]; then
  needs_install=1
fi

if [ ! -f node_modules/.package-lock.json ]; then
  needs_install=1
fi

if [ "$needs_install" -eq 0 ] && ! cmp -s package-lock.json node_modules/.package-lock.json; then
  needs_install=1
fi

if [ "$needs_install" -eq 1 ]; then
  npm ci --no-progress
fi

npm run release
