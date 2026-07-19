#!/usr/bin/env bash
set -euo pipefail
# build-installer.sh - Export container to Btrfs installer image
# Uses env: VARIANT, REGISTRY, OWNER (set by GitHub Actions step)

VARIANT="${VARIANT:?}"; REGISTRY="${REGISTRY:?}"; OWNER="${OWNER:?}"
case "$VARIANT" in
  plasma) DM_USER=sddm ;;
  *)      DM_USER=gdm ;;
esac

echo "::group::Create Btrfs image"
truncate -s 16G rootfs.img
mkfs.btrfs -L linux rootfs.img
echo "::endgroup::"

echo "::group::Create subvolume"
BTRFSROOT=/tmp/btrfs-root
mkdir "$BTRFSROOT"
sudo mount -o loop ./rootfs.img "$BTRFSROOT"
sudo btrfs subvolume create "$BTRFSROOT/@"
SUBVOLID=$(sudo btrfs subvolume show "$BTRFSROOT/@" | grep "Subvolume ID:" | awk '{print $3}')
sudo btrfs subvolume set-default "$SUBVOLID" "$BTRFSROOT"
sudo umount "$BTRFSROOT"
rmdir "$BTRFSROOT"
echo "::endgroup::"

echo "::group::Mount"
mkdir mountpoint
sudo mount -o loop,subvol=@ ./rootfs.img ./mountpoint/
sudo mkdir -p ./mountpoint/boot/efi
sudo mount -o size=512M,mode=0755 -t tmpfs none ./mountpoint/boot/efi/
echo "::endgroup::"

echo "::group::bootc install to-filesystem"
sudo podman run --rm --privileged --userns=host --pid=host --ipc=host \
  -v /dev:/dev \
  -v ./mountpoint:/target \
  "${REGISTRY}/${OWNER}/nabu-${VARIANT}:latest" \
  bootc install to-filesystem \
    --target-imgref "${REGISTRY}/${OWNER}/nabu-${VARIANT}:latest" \
    --root-mount-spec PARTLABEL=linux \
    --bootloader none \
    --karg "root=PARTLABEL=linux" \
    --karg "rw" \
    --karg "quiet loglevel=3" \
    --karg "systemd.show_status=auto" \
    --karg "rd.udev.log_level=3" \
    --karg "vt.global_cursor_default=0" \
    --karg "systemd.gpt_auto=no" \
    --karg "cryptomgr.notests" \
    --karg "fbcon=rotate:1" \
    /target
echo "::endgroup::"

echo "::group::Remount read-write"
sudo mount -o remount,rw ./mountpoint
echo "::endgroup::"

echo "::group::Clean target filesystem"
sudo ostree prune --repo=./mountpoint/ostree/repo --no-static-deltas 2>/dev/null || true
sudo rm -rf ./mountpoint/var/log/* ./mountpoint/var/tmp/* ./mountpoint/tmp/* 2>/dev/null || true
echo "::endgroup::"

echo "::group::Prepare chroot"
sudo mkdir -p ./mountpoint/proc ./mountpoint/sys ./mountpoint/dev \
  ./mountpoint/run ./mountpoint/tmp \
  ./mountpoint/dev/pts ./mountpoint/dev/shm
echo "::endgroup::"

echo "::group::Debug ostree layout"
sudo find ./mountpoint/ostree -maxdepth 4 -ls 2>/dev/null || true
echo "::endgroup::"

echo "::group::Find deployment"
SYSROOT_DIR=$(cd ./mountpoint && pwd)
DEPLOY_PATH=$(sudo ostree admin --sysroot=./mountpoint --print-current-dir)
DEPLOY_REL=${DEPLOY_PATH#$SYSROOT_DIR}
DEPLOY_NAME=$(basename "$DEPLOY_REL")
echo "Deployment path: $DEPLOY_REL"
echo "::endgroup::"

echo "::group::Find boot link"
# ostree-prepare-root requires ostree= to point to a symlink matching
# /ostree/boot.VERSION/OSNAME/BOOTCSUM/TREESERIAL
# bootc creates this automatically during finalization.
BOOT_VERSION=$(readlink "./mountpoint/ostree/boot.1")
BOOT_DIR="./mountpoint/ostree/${BOOT_VERSION}"
BOOT_LINK=$(find "$BOOT_DIR" -maxdepth 3 -type l -lname "*deploy/default/deploy/${DEPLOY_NAME}" 2>/dev/null | head -1)
if [ -z "$BOOT_LINK" ]; then
  echo "ERROR: Could not find boot link for deployment ${DEPLOY_NAME}"
  exit 1
fi
BOOT_LINK_PATH=${BOOT_LINK#./mountpoint}
echo "Boot link: $BOOT_LINK_PATH"
readlink -f "$BOOT_LINK"
echo "::endgroup::"

echo "::group::Inject overlays"
sudo rsync -a --exclude=overlay-post-apply ./base/overlay/ "./mountpoint${DEPLOY_REL}/" 2>/dev/null || true
sudo rsync -a --exclude=overlay-post-apply "./${VARIANT}/overlay/" "./mountpoint${DEPLOY_REL}/" 2>/dev/null || true

sudo mkdir -p "./mountpoint/${DEPLOY_REL#/}/boot/efi"
sudo mount --bind ./mountpoint/boot/efi "./mountpoint/${DEPLOY_REL#/}/boot/efi"

sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" bash - <<DEPLOY
cd /

kernver=\$(ls usr/lib/modules/ | sort -V | tail -1)
if [ -n "\$kernver" ]; then
  cat > etc/mkinitcpio.d/linux-nabu.preset << PRESET
ALL_kver="\$kernver"
PRESETS=('default' 'fallback')
default_uki="/boot/efi/EFI/arch/arch-linux-nabu.efi"
fallback_uki="/boot/efi/EFI/arch/arch-linux-nabu-fallback.efi"
default_cmdline="/etc/cmdline.d/root.conf"
fallback_cmdline="/etc/cmdline.d/root.conf"
default_hooks=("systemd" "autodetect" "modconf" "kms" "keyboard" "keymap" "consolefont" "block" "filesystems" "fsck" "ostree")
fallback_hooks=("systemd" "autodetect" "modconf" "kms" "keyboard" "keymap" "consolefont" "block" "filesystems" "fsck" "ostree")
PRESET
  sed -i "s|^DeviceTree=.*|DeviceTree=/boot/dtb-\$kernver|" usr/lib/kernel/uki.conf
fi

chown -R ${DM_USER}:${DM_USER} var/lib/${DM_USER}/.config/ 2>/dev/null || true

# Run overlay-post-apply scripts (excluded from rsync but present from container)
if [ -x /overlay-post-apply ]; then /overlay-post-apply; fi
if [ -x /usr/local/bin/overlay-post-apply ]; then /usr/local/bin/overlay-post-apply; fi

DEPLOY
chmod +x "./mountpoint${DEPLOY_REL}/opt/nabu/postinstall" 2>/dev/null || true
echo "::endgroup::"

echo "::group::Fix kernel cmdline"
sudo tee "./mountpoint${DEPLOY_REL}/etc/cmdline.d/root.conf" > /dev/null << CMDLINE
root=PARTLABEL=linux ostree=${BOOT_LINK_PATH} rw
CMDLINE
echo "::endgroup::"

echo "::group::Enable services"
sudo systemctl enable --root="./mountpoint${DEPLOY_REL}" "${DM_USER}" 2>/dev/null || true
echo "::endgroup::"

echo "::group::Generate UKI"
sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" mkdir -p /boot/efi/EFI/arch
KERNVER=$(sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" bash -c "ls usr/lib/modules/ | sort -V | tail -1")

# Debug: verify root.conf before UKI generation
echo "root.conf content:"
sudo cat "./mountpoint${DEPLOY_REL}/etc/cmdline.d/root.conf"

sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" /usr/libexec/nabu/bootc-uki-sync "$KERNVER" 2>/dev/null || \
  sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" bash -c "mkinitcpio -P" 2>&1 | grep -v 'gzip: stdout: Broken pipe' || true

# Debug: verify embedded cmdline in UKI
echo "::group::Verify UKI cmdline"
if [ -f "./mountpoint/boot/efi/EFI/arch/arch-linux-nabu.efi" ]; then
  sudo strings "./mountpoint/boot/efi/EFI/arch/arch-linux-nabu.efi" | grep -o 'ostree=[^ ]*' || echo "ostree= NOT FOUND in UKI!"
  sudo strings "./mountpoint/boot/efi/EFI/arch/arch-linux-nabu.efi" | grep -o 'root=PARTLABEL=[^ ]*' || echo "root= NOT FOUND in UKI!"
else
  echo "UKI file not found at /boot/efi/EFI/arch/arch-linux-nabu.efi"
fi
echo "::endgroup::"
echo "::endgroup::"

echo "::group::Package EFI"
sudo arch-chroot "./mountpoint/${DEPLOY_REL#/}" bash - <<PACK
cd /
rm -f opt/nabu/efi.tgz
tar cvzf opt/nabu/efi.tgz -C /boot/efi/ .
PACK
sudo umount "./mountpoint/${DEPLOY_REL#/}/boot/efi" 2>/dev/null || true
echo "::endgroup::"
