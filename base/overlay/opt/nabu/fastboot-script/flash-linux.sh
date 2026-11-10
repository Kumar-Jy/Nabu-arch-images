#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve images directory
if [ -d "$DIR/images" ]; then
    IMAGES_DIR="$DIR/images"
elif [ -f "$DIR/rootfs.img" ]; then
    IMAGES_DIR="$DIR"
else
    echo "Error: images directory not found at $DIR/images" >&2
    exit 1
fi

ROOTFS="$IMAGES_DIR/rootfs.img"
ESP="$IMAGES_DIR/esp.img"
UEFI="$IMAGES_DIR/alohauefi.img"

[ -f "$ROOTFS" ] || { echo "Error: rootfs image not found at $ROOTFS" >&2; exit 1; }
[ -f "$ESP" ] || { echo "Error: esp image not found at $ESP" >&2; exit 1; }

echo "==> Checking connected device..."
fastboot "$@" getvar product 2>&1 | grep -q 'product: *nabu' || { echo "Error: Device mismatch (expected nabu)"; exit 1; }

# Determine partition layout: dual/multi-boot (linux/esp) vs single-boot (userdata/cust)
HAS_LINUX=false
HAS_ESP=false
if fastboot "$@" getvar partition-size:linux 2>&1 | grep -q "partition-size:linux:[[:space:]]*[1-9]"; then
    HAS_LINUX=true
fi
if fastboot "$@" getvar partition-size:esp 2>&1 | grep -q "partition-size:esp:[[:space:]]*[1-9]"; then
    HAS_ESP=true
fi

if [ "$HAS_LINUX" = true ] && [ "$HAS_ESP" = true ]; then
    echo "==> Detected dual/multi-boot partition layout (linux + esp)"
    ROOT_PART="linux"
    ESP_PART="esp"
else
    echo "==> Using single-boot partition layout (userdata + cust)"
    ROOT_PART="userdata"
    ESP_PART="cust"
fi

# 1. Flash Aloha UEFI to boot partition (both slots)
if [ -f "$UEFI" ]; then
    echo "==> Flashing Aloha UEFI ($UEFI) to boot_ab..."
    fastboot "$@" flash boot_ab "$UEFI" || {
        echo "fastboot flash boot_ab failed, attempting per-slot flash..."
        fastboot "$@" flash boot_a "$UEFI" || { echo "Error flashing boot_a"; exit 1; }
        fastboot "$@" flash boot_b "$UEFI" || { echo "Error flashing boot_b"; exit 1; }
    }
else
    echo "Note: alohauefi.img not found in images/, skipping boot partition flash."
fi

# 2. Erase target partitions
echo "==> Erasing $ROOT_PART and $ESP_PART..."
fastboot "$@" erase "$ROOT_PART" || { echo "Error erasing $ROOT_PART"; exit 1; }
fastboot "$@" erase "$ESP_PART" || { echo "Error erasing $ESP_PART"; exit 1; }

# 3. Flash rootfs and ESP
echo "==> Flashing rootfs ($ROOTFS) to $ROOT_PART..."
fastboot "$@" flash "$ROOT_PART" "$ROOTFS" || { echo "Error flashing rootfs to $ROOT_PART"; exit 1; }

echo "==> Flashing ESP ($ESP) to $ESP_PART..."
fastboot "$@" flash "$ESP_PART" "$ESP" || { echo "Error flashing ESP to $ESP_PART"; exit 1; }

# 4. Reboot
echo "==> Flashing completed successfully! Rebooting..."
fastboot "$@" reboot || { echo "Error rebooting device"; exit 1; }
