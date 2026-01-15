#!/bin/bash

BINARY=$1
ROOTFS=$2

if [ -z "$BINARY" ] || [ -z "$ROOTFS" ]; then
    echo "Usage: $0 /path/to/binary /path/to/rootfs"
    exit 1
fi

mkdir -p "$ROOTFS/lib" "$ROOTFS/lib64" "$ROOTFS/usr/lib"

copy_if_missing() {
    local src=$1
    local dest="$ROOTFS$src"
    
    if [[ "$src" == *"linux-vdso"* ]]; then
        return
    fi

    if [ ! -f "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        cp -vL "$src" "$dest"
    else
        echo "Skipping: $src (already exists)"
    fi
}

ldd "$BINARY" | grep -o '/[^ ]*' | while read -r lib; do
    copy_if_missing "$lib"
done

LOADER=$(ldd "$BINARY" | grep "ld-linux" | awk '{print $1}')
if [ -n "$LOADER" ] && [ -f "$LOADER" ]; then
    copy_if_missing "$LOADER"
fi

echo "--- Sync Complete ---"
