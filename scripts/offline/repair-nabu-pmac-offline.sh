#!/usr/bin/env bash
# Offline repair of nabu-pmac on a bricked install, run from TWRP.
#
# Usage:  adb push scripts/offline/* /tmp/offline/   (from the repo root)
#         adb shell sh /tmp/offline/repair-nabu-pmac-offline.sh
#
# This script must run as root inside TWRP. It mounts the Linux rootfs at
# /dev/block/by-name/linux and overwrites the broken nabu-pmac unit, the
# unbounded script, and the stale drop-in with the fixed versions.
set -e

LINUX_PART=/dev/block/by-name/linux
MNT=/mnt/linux
SRC=/tmp/offline

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: must run as root (TWRP shell is root)." >&2
  exit 1
fi

[ -b "$LINUX_PART" ] || { echo "ERROR: $LINUX_PART not found." >&2; exit 1; }
for f in "$SRC/nabu-pmac.service" "$SRC/nabu-pmac-set" "$SRC/10-ordering.conf"; do
  [ -f "$f" ] || { echo "ERROR: missing $f" >&2; exit 1; }
done

# Force-unmount the linux partition if it is already mounted anywhere.
mount 2>/dev/null | while read -r dev _ mnt _; do
  case "$dev" in
    "$LINUX_PART" | */by-name/linux)
      umount -lf "$mnt" 2>/dev/null || true
      ;;
  esac
done

mkdir -p "$MNT"
mount -t ext4 "$LINUX_PART" "$MNT" 2>/dev/null || mount "$LINUX_PART" "$MNT"
trap 'umount "$MNT" 2>/dev/null || true' EXIT

install -Dm644 "$SRC/nabu-pmac.service" "$MNT/usr/lib/systemd/system/nabu-pmac.service"
install -Dm755 "$SRC/nabu-pmac-set" "$MNT/usr/local/bin/nabu-pmac-set"
install -Dm644 "$SRC/10-ordering.conf" "$MNT/etc/systemd/system/nabu-pmac.service.d/10-ordering.conf"
mkdir -p "$MNT/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/nabu-pmac.service "$MNT/etc/systemd/system/multi-user.target.wants/nabu-pmac.service"

umount "$MNT" 2>/dev/null || true
trap - EXIT

echo
echo "nabu-pmac offline repair complete."
echo "Reboot into Linux: deterministic MAC + Wi-Fi should now work."
