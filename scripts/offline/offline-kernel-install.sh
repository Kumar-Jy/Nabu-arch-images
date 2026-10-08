#!/bin/sh
set -e

echo "--- Nabu Offline Kernel Installer ---"

# Define paths
LINUX_PART="/dev/block/by-name/linux"
ESP_PART="/dev/block/by-name/esp"
MOUNT_POINT="/linux"

echo "[1/5] Creating mount point and mounting partitions..."
mkdir -p $MOUNT_POINT
mount $LINUX_PART $MOUNT_POINT
mount $ESP_PART $MOUNT_POINT/boot/efi

echo "[2/5] Setting up virtual filesystems..."
mount -t proc proc $MOUNT_POINT/proc
mount -t sysfs sys $MOUNT_POINT/sys
mount --bind /dev $MOUNT_POINT/dev
mount -t devpts devpts $MOUNT_POINT/dev/pts
ln -sf /proc/self/fd $MOUNT_POINT/dev/fd

echo "[3/5] Searching for kernel packages in /tmp..."
PKGS=$(ls /tmp/linux-nabu-*.pkg.tar.* 2>/dev/null)

if [ -z "$PKGS" ]; then
    echo "ERROR: No linux-nabu packages found in /tmp/"
    echo "Please run: adb push linux-nabu-*.pkg.tar.zst /tmp/"
    # Cleanup before exit
    umount $MOUNT_POINT/boot/efi $MOUNT_POINT/dev/pts $MOUNT_POINT/dev $MOUNT_POINT/sys $MOUNT_POINT/proc
    umount $MOUNT_POINT
    exit 1
fi

echo "Found packages: $PKGS"

echo "[4/5] Cleaning up old kernels and installing packages..."
# Run kclean first to ensure a clean state
TMPDIR=/tmp PATH=/usr/bin:/bin chroot $MOUNT_POINT nabu-kclean
# Install the new packages
TMPDIR=/tmp PATH=/usr/bin:/bin chroot $MOUNT_POINT pacman -U --noconfirm --overwrite '*' /tmp/linux-nabu-*.pkg.tar.*

echo "[5/5] Regenerating UKI boot image..."
TMPDIR=/tmp PATH=/usr/bin:/bin chroot $MOUNT_POINT /usr/libexec/nabu/uki-regenerate

echo "Cleaning up mounts..."
umount $MOUNT_POINT/boot/efi $MOUNT_POINT/dev/pts $MOUNT_POINT/dev $MOUNT_POINT/sys $MOUNT_POINT/proc
umount $MOUNT_POINT

echo "--- Success! You can now reboot your device. ---"
