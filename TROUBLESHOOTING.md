# Troubleshooting

Common issues on the Arch Linux ARM installer for the Xiaomi Pad 5 (nabu), and
how to fix them **without reinstalling**.

---

## Changing the pacman repo address

The nabu packages have moved to the new `[nabu]` repo — switch to it to get updates.

```bash
sudo sed -i '/^\[nabu\]$/,/^$/d' /etc/pacman.conf
sudo sed -i '/^\[nabu-alarm\]$/,/^$/d' /etc/pacman.conf

cat <<EOF | sudo tee -a /etc/pacman.conf
[nabu]
SigLevel = Never
Server = https://github.com/Kumar-Jy/nabu-pkgs/releases/download/repo
EOF

sudo pacman -Sy
```

---

## Wi-Fi MAC is random or the interface is renamed (`wlan0` → `wld0`)

`nabu-pmac` derives Wi-Fi MAC from the board serial and sets it
on boot. Older images ran the service *after* NetworkManager, so
NetworkManager's own (random per-boot) MAC won; newer systemd also renames the
wireless interface (`wlan0` → `wld0`).

### Option A — pacman package (recommended)

Install the fixed `nabu-pmac` package from the `[nabu]` repo:

```bash
sudo rm -rf /etc/systemd/system/nabu-pmac.service.d

sudo pacman -S --overwrite "/usr/lib/systemd/system/nabu-pmac.service" \
               --overwrite "/etc/systemd/network/10-wlan.link" nabu-pmac
sudo systemctl daemon-reload
sudo systemctl enable --now nabu-pmac
sudo reboot
```

### Verify

After applying any option, reboot and confirm the MAC is stable:

```bash
ip link show wlan0
```

---


## Failed to boot after kernel update

Symptoms: stuck at rEFInd / black screen, or boot error `Timed out waiting for device /dev/disk/by-partlabel/linux`.

### Fix from TWRP (Offline)

If a kernel update broke booting or you need to install/downgrade a kernel (download packages from [nabu-pkgs releases](https://github.com/Kumar-Jy/nabu-pkgs/releases/tag/repo)):

```bash
adb shell
mount /dev/block/by-name/linux /linux
mount /dev/block/by-name/esp /linux/boot/efi
mount -t proc proc /linux/proc
mount -t sysfs sys /linux/sys
mount --bind /dev /linux/dev
mount -t devpts devpts /linux/dev/pts
ln -sf /proc/self/fd /linux/dev/fd

# (Optional) Install / downgrade kernel packages pushed via adb
# adb push linux-nabu-*.pkg.tar.xz /linux/tmp/
# TMPDIR=/tmp PATH=/usr/bin:/bin chroot /linux pacman -U --overwrite '*' /tmp/linux-nabu-*.pkg.tar.xz

# Regenerate UKI boot image
TMPDIR=/tmp PATH=/usr/bin:/bin chroot /linux /usr/libexec/nabu/uki-regenerate

# Unmount and reboot
umount /linux/boot/efi /linux/dev/pts /linux/dev /linux/sys /linux/proc /linux
reboot
```

### Fix Online (if tablet boots)

Re-run UKI regeneration directly from Linux:

```bash
sudo /usr/libexec/nabu/uki-regenerate
```

---

## Cleaning older kernel versions

> [!WARNING]
> You must verify that the tablet boots successfully with the new kernel before removing older versions, to ensure you do not delete a working fallback.

### Online (from running Linux)

In online mode, the ESP partition is mounted under `/boot` (at `/boot/efi`):

1. Confirm the running kernel:
   ```bash
   uname -r
   ```
2. List installed kernels, module trees, and EFI images:
   ```bash
   ls -l /boot
   ls -l /usr/lib/modules
   ls -l /boot/efi/EFI/arch
   ```
3. Remove old unused kernel files, modules, and old fallback UKI (replace `<old-version>`):
   ```bash
   sudo rm -rf /boot/vmlinu*-<old-version> /boot/dtb-<old-version> /usr/lib/modules/<old-version>
   sudo rm -f /boot/efi/EFI/arch/*-old.efi
   ```

### Offline (from TWRP)

In offline mode, ESP is on `/dev/block/by-name/esp` containing `EFI/arch/*-old.efi`:

1. Mount Linux and ESP partitions:
   ```bash
   adb shell
   mount /dev/block/by-name/linux /linux
   mount /dev/block/by-name/esp /linux/boot/efi
   ```
2. Identify and remove older kernel files, modules, and old fallback UKI (replace `<old-version>`):
   ```bash
   ls -l /linux/boot
   ls -l /linux/usr/lib/modules
   ls -l /linux/boot/efi/EFI/arch

   rm -rf /linux/boot/vmlinu*-<old-version> /linux/boot/dtb-<old-version> /linux/usr/lib/modules/<old-version>
   rm -f /linux/boot/efi/EFI/arch/*-old.efi
   ```
3. Unmount:
   ```bash
   umount /linux/boot/efi /linux
   ```

---

## Kernel update not applied / UKI not regenerated

- Check `uname -r`. The `linux-nabu` package rebuilds the UKI on install; force
  a rebuild with `sudo /usr/libexec/nabu/uki-regenerate`.
- pacman compares only `pkgver`/`pkgrel`, never the kernel version string. Bump
  one on every custom build, or the install is skipped and the UKI is not rebuilt.
- Verify with `ls -l /boot/efi/EFI/arch/`.

---

## Removing unused generic PC firmware packages

The tablet only requires `linux-firmware-xiaomi-nabu` (device-specific DSP/GPU/touch blobs) and `linux-firmware-atheros` (Wi-Fi/Bluetooth blobs) along with `linux-firmware-whence`.

`linux-nabu` and `linux-firmware-xiaomi-nabu` depend directly on `linux-firmware-whence` and `linux-firmware-atheros`, avoiding the generic `linux-firmware` meta-package (which pulls ~850 MB of Intel, Nvidia, AMD, Mediatek, Broadcom, etc. firmware).

If upgrading an existing installation that still has legacy generic PC firmware packages installed, remove them to reclaim ~850 MB of storage:

```bash
sudo pacman -Rdd linux-firmware linux-firmware-intel linux-firmware-nvidia linux-firmware-amdgpu linux-firmware-amd linux-firmware-mediatek linux-firmware-broadcom linux-firmware-realtek linux-firmware-radeon linux-firmware-cirrus linux-firmware-ti linux-firmware-other
sudo pacman -S --needed linux-firmware-whence linux-firmware-atheros
```

In `/etc/pacman.conf`, `IgnorePkg` only needs device kernel packages:
```ini
IgnorePkg = linux-nabu linux-nabu-headers
```
