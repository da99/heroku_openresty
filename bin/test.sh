#!/usr/bin/env bash
#
#
THE_ARGS="$@"
THIS_DIR="$(dirname "$( dirname "$(realpath "$0")" )" )"

set -u -e -o pipefail

DIR="/tmp/test_heroku_openresty"
BUILD_DIR="$DIR/build"
CACHE_DIR="$DIR/cache"
ENV_DIR="$DIR/env"

export HOME="$DIR/home/apps"
mkdir -p "$HOME"

rm -rf "$DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$ENV_DIR"

cd "$DIR"

"$THIS_DIR/bin/detect"
"$THIS_DIR/bin/compile" "$BUILD_DIR" "$CACHE_DIR" "$ENV_DIR"

if [[ -f "$THIS_DIR/bin/release" ]]; then
  "$THIS_DIR/bin/release"
fi
