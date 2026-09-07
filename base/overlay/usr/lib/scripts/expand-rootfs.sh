#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
  echo "expand-rootfs: must be run as root" >&2
  exit 0
fi

if [ -f /var/lib/.rootfs-expanded ]; then
  echo "expand-rootfs: already expanded, skipping."
  exit 0
fi

echo "expand-rootfs: expanding root filesystem to fill partition..."

# Find the actual btrfs device from /proc/mounts
# In bootc/ostree, / and /sysroot are the same device/subvolume.
# Use / (rw) for resize since /sysroot is mounted read-only.
BTRFS_DEV=""
BTRFS_MNT=""
while IFS= read -r line; do
  dev=$(echo "$line" | awk '{print $1}')
  mp=$(echo "$line" | awk '{print $2}')
  fstype=$(echo "$line" | awk '{print $3}')
  if [ "$fstype" = "btrfs" ]; then
    if [ "$mp" = "/" ]; then
      BTRFS_DEV="$dev"
      BTRFS_MNT="$mp"
      break
    elif [ -z "$BTRFS_DEV" ] && [ "$mp" = "/sysroot" ]; then
      BTRFS_DEV="$dev"
      BTRFS_MNT="$mp"
    fi
  fi
done < /proc/mounts

if [ -z "$BTRFS_DEV" ]; then
  echo "expand-rootfs: ERROR - could not find btrfs device" >&2
  exit 0
fi

# Safety check: verify this is the Linux partition (label="linux")
PART_LABEL=$(blkid -s LABEL -o value "$BTRFS_DEV" 2>/dev/null || true)
if [ "$PART_LABEL" != "linux" ]; then
  echo "expand-rootfs: ERROR - device $BTRFS_DEV has label '$PART_LABEL', expected 'linux'. Aborting." >&2
  exit 0
fi

echo "expand-rootfs: found Linux btrfs device: $BTRFS_DEV (label: $PART_LABEL)"

# Get current filesystem size
echo "expand-rootfs: current filesystem size:"
btrfs filesystem show "$BTRFS_DEV" 2>/dev/null || true

# Resize the filesystem to fill the partition
for i in 1 2 3; do
  if btrfs filesystem resize max "$BTRFS_MNT"; then
    touch /var/lib/.rootfs-expanded
    echo "expand-rootfs: success (attempt $i)."
    btrfs filesystem show "$BTRFS_DEV" 2>/dev/null || true
    exit 0
  fi
  echo "expand-rootfs: resize attempt $i failed, retrying in 2s..."
  sleep 2
done

echo "expand-rootfs: WARNING - failed after 3 attempts. Booting continues with current size." >&2
exit 0
