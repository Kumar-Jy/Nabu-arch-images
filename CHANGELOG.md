# Changelog

All notable changes to **Arch Linux ARM for Xiaomi Pad 5 (nabu)** are documented here.

---

## [Build 2026-10-08]

### ⚙️ Kernel & Boot
- **Kernel 6.18.55-1:** Updated to new 6.18 LTS branch.
  - **Display Fixes:** Resolved DSI PLL lock failures and restored PM runtime resume for more stable boot and UEFI handover.
  - **Storage:** Added Samsung UFS compatibility via DT frequency tables and reset quirks.
  - **Hardware Support:** Full support for OV13B10/OV8856 cameras, SM8150 audio (24-bit mic), and PM8150B SMB5 charger with USB-PD sink.

### 🖥️ Desktop & Apps
- **stylus-popup:** Added "Dynamic Island" style status pill for the stylus.
  - Displays pen battery/charging state via `wlr-layer-shell`.
  - Supports Gen 1/Gen 2 detection and customizable side-button shell commands.
- **iio-sensor-proxy (3.9-5):** Added proximity sensor support by decoding the Xiaomi `sar_algo_1` sensor data.

---

## [Build 2026-09-30]

### ⚙️ Kernel & Boot
- **Kernel 6.14.11-10.1:** Backlight reliably turns back on after wake from sleep (KTZ8866 PM resume hook).
- **Suspend/Sleep:** Faster and cleaner sleep entry (grace period reduced to 300ms).
- **Sensors & Subsystems:** Stable FastRPC/SLPI sensor communication over QRTR.

### 🖥️ Desktop & Apps
- **Auto-Rotation Fixed:** Accelerometer orientation, ambient light, and compass now work reliably in KDE Plasma and GNOME without crashing (`iio-sensor-proxy` 3.9-4).
- **Tablet Mode CPU Fix:** Reduced daemon idle CPU usage from ~10% down to **0.0%**; unprivileged mode toggle via `/run/nabu-tablet-mode/mode` (`nabu-tablet-mode` 1.0.0-11).
- **Auto-Brightness:** Daemon automatically reconnects to sensors after sleep/wake (`nabu-autobrightness` 1.0.0-3).
- **Camera Studio:** Added tap-to-focus autofocus, manual focus slider, video recording, and tablet rotation tracking (`camera-studio` 1.0.6-1).
- **Repository Setup:** `[nabu]` repo now prioritizes over upstream mirrors to prevent version conflict warnings.
- **Package Changelogs:** Terminal highlights during `pacman -Syu` and native query support (`pacman -Qc`).
- **Kernel Backup Cleaner:** Added `nabu-kclean` tool to safely clean up old backup UKIs and module trees (*.old) created during kernel updates.

### ⚠️ Known Issues
- **Audio:** Minor crackling at maximum volume.
- **Camera:** Image processing not on par with Android; Qualcomm ISP tuning is WIP.

---

## [Build 2026-09-24]

### ⚙️ Kernel & Boot
- **Kernel 6.14.11-10:** Merged `6.14` branch with MIDI, suspend/wake, VPU, NTFS3 & Bluetooth audio fixes.
- **Headers & DKMS:** Pre-installed for on-device module builds (e.g. DisplayLink).
- **Safe UKI Boot:** Auto-regenerates the UKI on kernel install/upgrade, keeping the previous known-good copy (`uki-regenerate`).
- **Default Kernel:** Installer default updated to `6.14.11-10`.

### 🖥️ Desktop & Apps
- **DisplayLink:** Out-of-the-box USB monitor support (`evdi` + service enabled).
- **nabu-torch:** Flashlight app with brightness slider on GNOME & Plasma.
- **Lighter Base:** Trimmed redundant packages to improve performance.

### ⚠️ Known Issues
- **Rotation:** Sensor may pause after sleep (recovery fix in progress).
- **Audio:** Minor crackling at maximum volume.
- **Camera:** Image processing not on par with Android; Qualcomm ISP tuning is WIP.

---

## [Build 2026-09-18]

### 🚀 Initial Release
- **Desktops:** Separate disk images for KDE Plasma and GNOME.
- **HW Video Decode:** Iris/Venus accelerated playback via `iris-vaapi`.
- **Audio & BT:** Quad CS35L41 speakers with ALSA/PipeWire; Bluetooth 5.0.
- **Brightness:** Ambient light sensor support on Plasma & GNOME.
- **Touch & Pen:** 10-point multi-touch and Xiaomi Smart Pen stylus.
- **Cameras:** Front & rear camera support via `camera-studio`.
- **Multi-Boot:** Bundled DBKP + rEFInd bootloader for Windows/Android/Linux.
