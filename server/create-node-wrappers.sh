#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
RUNTIME_DIR="$RELEASE_DIR/node_modules/uebersicht-runtime"
NODE_VERSION="$(node -p 'process.version')"
NODE_DIST_VERSION="${NODE_VERSION#v}"
CACHE_DIR="${UEBERSICHT_NODE_CACHE_DIR:-/tmp/uebersicht-node}"
DEFAULT_X64_NODE="$CACHE_DIR/node-${NODE_VERSION}-darwin-x64/bin/node"
DEFAULT_ARM64_NODE="$CACHE_DIR/node-${NODE_VERSION}-darwin-arm64/bin/node"
X64_NODE_BIN="${UEBERSICHT_NODE_X64_BIN:-$DEFAULT_X64_NODE}"
ARM64_NODE_BIN="${UEBERSICHT_NODE_ARM64_BIN:-$DEFAULT_ARM64_NODE}"

download_node_bin() {
  local arch="$1"
  local destination="$2"
  local archive="node-v${NODE_DIST_VERSION}-darwin-${arch}.tar.gz"
  local url="https://nodejs.org/dist/v${NODE_DIST_VERSION}/${archive}"
  local tmpdir

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  mkdir -p "$(dirname "$destination")"

  curl -fsSL "$url" -o "$tmpdir/$archive"
  tar -xzf "$tmpdir/$archive" -C "$tmpdir"
  cp -f "$tmpdir/node-v${NODE_DIST_VERSION}-darwin-${arch}/bin/node" "$destination"
  chmod 755 "$destination"
}

ensure_node_bin() {
  local path="$1"
  local arch="$2"

  if [ ! -x "$path" ]; then
    download_node_bin "$arch" "$path"
  fi
}

copy_node() {
  local source="$1"
  local dest="$2"

  cp -f "$source" "$dest"
  chmod 755 "$dest"
}

create_launcher() {
  local name="$1"
  local target="$2"

  cat > "$RELEASE_DIR/$name" <<EOF
#!/bin/sh
set -eu
DIR="\$(CDPATH= cd -- "\$(dirname "\$0")" && pwd)"
exec "\$DIR/node_modules/uebersicht-runtime/$target/node" "\$@"
EOF
  chmod 755 "$RELEASE_DIR/$name"
}

create_auto_launcher() {
  cat > "$RELEASE_DIR/localnode" <<'EOF'
#!/bin/sh
set -eu
DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

case "$(uname -m)" in
  arm64)
    ARCH_DIR="arm64"
    ;;
  *)
    ARCH_DIR="x64"
    ;;
esac

exec "$DIR/node_modules/uebersicht-runtime/$ARCH_DIR/node" "$@"
EOF
  chmod 755 "$RELEASE_DIR/localnode"
}

ensure_node_bin "$X64_NODE_BIN" "x64"
ensure_node_bin "$ARM64_NODE_BIN" "arm64"

rm -rf "$RUNTIME_DIR"
mkdir -p "$RUNTIME_DIR/x64" "$RUNTIME_DIR/arm64"

copy_node "$X64_NODE_BIN" "$RUNTIME_DIR/x64/node"
copy_node "$ARM64_NODE_BIN" "$RUNTIME_DIR/arm64/node"

create_auto_launcher
create_launcher "node-x64" "x64"
create_launcher "node-arm64" "arm64"
