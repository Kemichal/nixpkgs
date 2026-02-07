#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix yarn-berry.yarn-berry-fetcher

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(nix-build --no-out-link -E '(import <nixpkgs> {}).callPackage ./source.nix {}')"

# Build outline source to get yarn.lock
echo "Building outline source..."
SRC="$(nix build "$NIXPKGS_ROOT#outline.src" --no-link --print-out-paths)"

echo "Updating yarnHash"
yarn-berry-fetcher missing-hashes "$SOURCE_DIR/yarn.lock" > missing-hashes.json
YARN_HASH="$(yarn-berry-fetcher prefetch "$SOURCE_DIR/yarn.lock" ./missing-hashes.json 2>/dev/null)"
echo "yarnHash = $YARN_HASH"
# Replace the first "hash = "..." (yarn offline cache)
sed -i '0,/hash = "[^"]*"/{s//hash = "'"$YARN_HASH"'"/}' default.nix
