#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
APP_BUNDLE_NAME="${APP_BUNDLE_NAME:-Uebersicht}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/UebersichtReleaseDerivedData}"
APP_SOURCE="${1:-}"

if [ -z "$APP_SOURCE" ]; then
  APP_SOURCE="$(find "$DERIVED_DATA_PATH/Build/Products/Release" -maxdepth 1 -name '*.app' -print -quit)"
fi

if [ -z "$APP_SOURCE" ] || [ ! -d "$APP_SOURCE" ]; then
  echo "release app bundle not found" >&2
  exit 1
fi

INFO_PLIST="$APP_SOURCE/Contents/Info.plist"
EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"

INTEL_APP="$DIST_DIR/intel/$APP_BUNDLE_NAME.app"
ARM_APP="$DIST_DIR/arm64/$APP_BUNDLE_NAME.app"
INTEL_ZIP="$DIST_DIR/${APP_BUNDLE_NAME}-${VERSION}-intel.zip"
ARM_ZIP="$DIST_DIR/${APP_BUNDLE_NAME}-${VERSION}-arm64.zip"

thin_bundle() {
  local arch="$1"
  local app_path="$2"
  local remove_wrapper="$3"
  local remove_runtime="$4"
  local executable_path="$app_path/Contents/MacOS/$EXECUTABLE_NAME"
  local fsevents_path

  lipo -thin "$arch" "$executable_path" -output "$executable_path"

  fsevents_path="$(find "$app_path" -name fsevents.node -print -quit)"
  if [ -n "$fsevents_path" ]; then
    lipo -thin "$arch" "$fsevents_path" -output "$fsevents_path"
  fi

  rm -rf \
    "$app_path/Contents/Resources/$remove_wrapper" \
    "$app_path/Contents/Resources/node_modules/uebersicht-runtime/$remove_runtime"
}

create_zip() {
  local app_path="$1"
  local zip_path="$2"
  local parent_dir
  local bundle_name

  parent_dir="$(dirname "$app_path")"
  bundle_name="$(basename "$app_path")"

  if command -v xattr >/dev/null 2>&1; then
    xattr -cr "$app_path" || true
  fi

  (
    cd "$parent_dir"
    zip -qry -X "$zip_path" "$bundle_name"
  )
}

rm -rf "$DIST_DIR/intel" "$DIST_DIR/arm64" "$INTEL_ZIP" "$ARM_ZIP"
mkdir -p "$DIST_DIR/intel" "$DIST_DIR/arm64"

ditto "$APP_SOURCE" "$INTEL_APP"
ditto "$APP_SOURCE" "$ARM_APP"

thin_bundle "x86_64" "$INTEL_APP" "node-arm64" "arm64"
thin_bundle "arm64" "$ARM_APP" "node-x64" "x64"

create_zip "$INTEL_APP" "$INTEL_ZIP"
create_zip "$ARM_APP" "$ARM_ZIP"

printf 'Packaged %s\n' "$INTEL_APP"
printf 'Packaged %s\n' "$ARM_APP"
printf 'Created %s\n' "$INTEL_ZIP"
printf 'Created %s\n' "$ARM_ZIP"
