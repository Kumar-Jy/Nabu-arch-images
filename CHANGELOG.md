# Changelog

All notable changes to **Arch Linux ARM (Atomic / bootc) for Xiaomi Pad 5 (nabu)** are documented here.

---

## [Build 2026-11-10]

### ⚙️ Kernel & Boot
- **Kernel 7.3.3-3:** Tracks `linux-nabu` / `linux-nabu-headers` 7.3.3-3 from the `[nabu]` repository.
  - **Display (120Hz ↔ 60Hz):** Novatek NT36523 panel pen-sync sequencing & vertical front porch (VFP) timing tuned, eliminating gray screen and loss of sync on 60Hz mode switches.
  - **Power & Charging:** PM8150B BMS driver logic corrected to accurately report `Charging` (instead of falsely showing `Discharging`) while plugged in. Enabled LN8000 33W direct fast charge support with 5s CC stickiness.
  - **Audio & Headset:** Added wired 3.5mm headphone playback DAI link in DTS with dedicated PCM channel, and DSP AFE port recovery across suspend.
  - **Stylus (Smart Pen):** Clean suspend/resume handling and bad packet filtering.
- **Aloha UEFI & Standalone Single-Boot:** Bundled `alohauefi.img` into installer images.
  - Added partition compatibility udev rules (`99-nabu-partlabel.rules`) mapped into UKI initramfs to dynamically resolve Btrfs `linux` and FAT32 `esp` partitions whether flashed onto `userdata`/`cust` (single-boot) or `linux`/`esp` (dual-boot).
  - Updated `flash-linux.sh` and `flash-linux.bat` to detect and flash either single-boot or dual-boot layouts automatically.
- **Date, Time & Writable `/etc` Fix:** Configured `[sysroot] readonly = true` in `prepare-root.conf` and embedded into initramfs so `ostree-prepare-root` automatically provisions a persistent, writable bind-mount for `/etc` and `/var`.
  - Added Polkit rule (`49-nopasswd-date-time.rules`) allowing `wheel` desktop users to change time, timezone, and NTP in GNOME and KDE Settings without authentication errors.
  - Removed faulty `mount --bind` logic from `timezone-setup` and `nabu-set-timezone`, allowing native `timedatectl` and GUI timezone changes to persist seamlessly across reboots.
- **Hardware Calibration & Sensor Telemetry:** Mounted `/mnt/vendor/persist` in `/etc/fstab` so DSP sensors (`sns_reg.conf`) and Wi-Fi drivers can access factory calibration.
- **Wi-Fi Persistent MAC Fix:** Updated `nabu-pmac-set` to safely bring the wireless interface down before updating the MAC address and re-upping it.
- **Complete Boot Cmdline:** Preserved `fbcon=rotate:1`, `systemd.gpt_auto=no`, `quiet loglevel=3`, and `cryptomgr.notests` across UKI sync and build-installer stages.

### 🖥️ Desktop & Hardware Parity
- **Hardware Video Decode:** Included `iris-vaapi` driver in `base/Containerfile` for hardware-accelerated video playback in browsers and media players.
- **Sensors & Subsystems:** Included `qrtr`, `tqftpserv`, `rmtfs`, `hexagonrpcd`, `libssc`, and `iio-sensor-proxy` in `base/Containerfile` with services enabled out of the box for automatic screen rotation and ambient light sensing.
- **GNOME Parity:** Added `nabu-autobrightness` and `stylus-popup` along with user systemd service enablement.
- **Plasma:** Full-size Plasma Keyboard add-on enabled by default (English + Hindi layouts).

---

## [Build 2026-11-01]

### ⚙️ Kernel & Boot
- **Kernel 7.3.1-1:** Installer default moved to the 7.3 kernel series (`linux-nabu` from the `[nabu]` repo).
  - **Sleep Stability:** Restored 300ms hardware timer s2idle grace window (`pm_s2idle_set_wake_irq` on PM8941 power key) to eliminate immediate auto-wakeups on power button release.
  - **Keyboard Cover:** Preserved active pin control across display blanking in `xiaomi_keyboard` to prevent I2C bus lockups.

### 🖥️ Desktop & Apps
- **Plasma:** The full-size Plasma Keyboard add-on (`plasma-keyboard-full-layout`) is installed and enabled by default for the `user` account.
- **GNOME:** Added `evolution-data-server` to fix repeated `gnome-shell-calendar-server` crashes from missing `libecal`/`libedataserver` sonames.
