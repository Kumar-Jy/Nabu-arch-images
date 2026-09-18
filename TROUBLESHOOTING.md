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

`nabu-pmac` derives a deterministic Wi-Fi MAC from the board serial and sets it
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

`--overwrite` is required once because the running image already contains
unowned copies of the service file and the `.link` file at those paths. The
`rm -rf` clears any stale drop-in left by the earlier helper script (it is a
no-op on a stock image).

### Option B — helper script

```bash
sudo curl -fL -o /tmp/fix-nabu-pmac.sh \
  https://raw.githubusercontent.com/Kumar-Jy/Nabu-arch-images/main/scripts/fix-nabu-pmac.sh
sudo bash /tmp/fix-nabu-pmac.sh
sudo reboot
```

The script pins the interface name, replaces the setup script with a bounded-wait
version (so it can never stall boot), and orders the service to run before
NetworkManager.

Or copy-paste the equivalent steps manually:

```bash
sudo mkdir -p /etc/systemd/network
sudo tee /etc/systemd/network/10-wlan.link >/dev/null <<'EOF'
[Match]
OriginalName=wlan*
[Link]
Name=wlan0
EOF

sudo mkdir -p /etc/systemd/system/nabu-pmac.service.d
sudo tee /etc/systemd/system/nabu-pmac.service.d/10-ordering.conf >/dev/null <<'EOF'
[Unit]
Wants=network-pre.target
Before=network-pre.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nabu-pmac
sudo reboot
```

### Option C — offline TWRP recovery (when Linux won't boot)

If a broken `nabu-pmac` service prevents Linux from booting, repair it from
TWRP without entering the system. With the device in TWRP (ADB available), run
the following from the repository root:

```bash
adb push scripts/offline/* /tmp/offline/
adb shell sh /tmp/offline/repair-nabu-pmac-offline.sh
```

The script mounts the Linux rootfs at `/dev/block/by-name/linux` and overwrites
the stale `nabu-pmac` unit, setup script and drop-in with the fixed versions.
Reboot into Linux afterwards.

### Verify

After applying any option, reboot and confirm the MAC is stable:

```bash
ip link show wlan0
```

---

## Linux won't boot

### Hang during Wi-Fi MAC setup
If boot hangs during the Wi-Fi MAC setup, the installed `nabu-pmac` service is
the old unbounded version. Repair it from TWRP with **Option C** above.

### Tablet does not boot after a kernel update

The UKI no longer matches the installed kernel. On older images either
`uki-regenerate` picked a stale `*.old`/`*.safe` module tree (the new kernel got
no UKI and `arch-linux-nabu-old.efi` is a copy of the same stale image), or
`systemd-ukify` was replaced and stripped the Device Tree / `acpi=off`.

Symptoms: stuck at rEFInd or a black screen, or `Timed out waiting for device
/dev/disk/by-partlabel/linux` with `the root account is locked`.

#### Fix from TWRP (Offline)

```bash
adb shell
mount /dev/block/by-name/linux /linux
mount /dev/block/by-name/esp /linux/boot/efi
mount -t proc proc /linux/proc
mount -t sysfs sys /linux/sys
mount --bind /dev /linux/dev

# 1. If nabu-boot-tools is installed, run automated repair:
env -i PATH=/usr/bin:/usr/sbin:/bin:/sbin TMPDIR=/tmp chroot /linux /usr/bin/nabu-boot-repair

# Or manual repair if nabu-boot-tools is not yet installed:
# Check installed kernel: ls /linux/usr/lib/modules (e.g. 6.14.11-1-nabu)
# sed -i 's|^ALL_kver=.*|ALL_kver="/boot/vmlinuz-<kernel-version>"|' /linux/etc/mkinitcpio.d/linux-nabu.preset
# sed -i -e 's/\bautodetect\b//g' -e 's/\bmicrocode\b//g' /linux/etc/mkinitcpio.conf
# printf '[UKI]\nDeviceTree=/boot/dtb-linux-nabu\n' > /linux/etc/kernel/uki.conf
# grep -q 'acpi=off' /linux/etc/cmdline.d/root.conf || sed -i 's/$/ acpi=off/' /linux/etc/cmdline.d/root.conf
# grep -q 'fw_devlink=permissive' /linux/etc/cmdline.d/root.conf || sed -i 's/$/ fw_devlink=permissive/' /linux/etc/cmdline.d/root.conf
# env -i PATH=/usr/bin:/usr/sbin:/bin:/sbin TMPDIR=/tmp chroot /linux mkinitcpio -P

# 2. Unmount and reboot
umount /linux/boot/efi /linux/dev /linux/sys /linux/proc /linux
reboot
```

#### Fix Online (if tablet boots)

Install `nabu-boot-tools` from the `[nabu]` repo, which automatically configures your boot parameters, updates `uki-regenerate`, and verifies the UKI:

```bash
sudo pacman -Sy --overwrite '*' nabu-boot-tools
```

You can also re-run the repair at any time:
```bash
sudo nabu-boot-repair
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
