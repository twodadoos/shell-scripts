#!/bin/bash

####################### USAGE ########################
# Make script executable
# chmod +x extract-image-fs.sh

# Run example
# bash extract-image-fs.sh alpine:latest ./alpine-rootfs

# Browse filesystem locally
# ls ./alpine-rootfs/
######################################################

set -euo pipefail

IMAGE="$1"
OUTDIR="${2:-./image-fs}"

# Temp working dir
WORKDIR=$(mktemp -d)

echo "[*] Saving image..."
docker image save "$IMAGE" -o "$WORKDIR/image.tar"

echo "[*] Extracting image archive..."
mkdir -p "$WORKDIR/extracted"
tar -xf "$WORKDIR/image.tar" -C "$WORKDIR/extracted"

echo "[*] Reconstructing filesystem..."
mkdir -p "$OUTDIR"

# Read manifest.json to get layer order
LAYERS=$(jq -r '.[0].Layers[]' "$WORKDIR/extracted/manifest.json")

for layer in $LAYERS; do
    echo "  Applying layer: $layer"
    tar -xf "$WORKDIR/extracted/$layer" -C "$OUTDIR"
done

echo "[+] Done! Final filesystem is in: $OUTDIR
