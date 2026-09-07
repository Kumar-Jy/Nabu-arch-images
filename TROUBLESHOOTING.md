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

- If boot hangs during the Wi-Fi MAC setup, the installed `nabu-pmac` service is
  the old unbounded version. Repair it from TWRP with **Option C** above.

---

## Kernel update not applied / UKI not regenerated

- After `sudo pacman -Syu`, check the running kernel with `uname -r`. The
  `linux-nabu` package rebuilds the UKI automatically on install/upgrade. If the
  UKI is missing or stale, regenerate it with the fallback handler:

  ```bash
  sudo /usr/libexec/nabu/uki-regenerate
  ```

- If you installed a **custom/local kernel** and pacman reports *"up to date"*,
  it decides this using only `pkgver`/`pkgrel` — never the kernel version
  string. Bump `pkgver` (or `pkgrel`) on every build, otherwise the install is
  skipped and the UKI is not regenerated.

- Verify the UKI was produced:

  ```bash
  findmnt /boot/efi
  ls -l /boot/efi/EFI/arch/
  ```
