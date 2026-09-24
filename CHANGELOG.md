# Changelog

All notable changes to **Arch Linux ARM for Xiaomi Pad 5 (nabu)** are documented here.

---

## [Build 2026-09-25]

### ⚙️ Kernel & Boot
- **Kernel 6.14.11-10:** Merged suspend/wake, VPU, NTFS3, MIDI & audio fixes.
- **Headers & DKMS:** Pre-installed for on-device module builds (e.g. DisplayLink).
- **Safe UKI Boot:** Auto-rebuilds UKI with fallback backup (`uki-regenerate`).
- **Default Kernel:** Installer default updated to `6.14.11-10`.

### 🖥️ Desktop & Apps
- **DisplayLink:** Out-of-the-box USB monitor support (`evdi` + service enabled).
- **nabu-torch:** Flashlight app with brightness slider on GNOME & Plasma.
- **nabu-tablet-mode:** Standalone package for clean auto-rotation updates.
- **Lighter Base:** Trimmed redundant packages to improve performance.

### ⚠️ Known Issues
- **Rotation:** Sensor may pause after sleep (recovery fix in progress).
- **Audio:** Minor crackling at maximum volume.
- **Camera:** Basic capture works; Qualcomm ISP tuning is WIP.

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