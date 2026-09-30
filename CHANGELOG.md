# Changelog - Arch Linux ARM for Xiaomi Pad 5 (nabu)

All notable changes to the `nabu` Arch Linux ARM disk images, installer packages, and hardware integration are documented in this file.

---

## [Build 2026-09-30]

### Kernel side
- **Kernel 6.14.11-10.1**: Backlight reliably turns back on after wake from sleep (KTZ8866 PM resume hook)
- **Suspend/Sleep**: Faster and cleaner sleep entry (grace period reduced to 300ms)
- **Sensors & Subsystems**: Stable FastRPC/SLPI sensor communication over QRTR

### User space & Hardware
- **Auto-Rotation Fixed**: Accelerometer orientation, ambient light, and compass now work reliably in KDE Plasma and GNOME without crashing (`iio-sensor-proxy` 3.9-4)
- **Tablet Mode CPU Fix**: Reduced daemon idle CPU usage from ~10% down to **0.0%**; unprivileged mode toggle via `/run/nabu-tablet-mode/mode` (`nabu-tablet-mode` 1.0.0-11)
- **Auto-Brightness**: Daemon automatically reconnects to sensors after sleep/wake (`nabu-autobrightness` 1.0.0-3)
- **Camera Studio**: Added tap-to-focus autofocus, manual focus slider, video recording, and tablet rotation tracking (`camera-studio` 1.0.6-1)
- **Repository Setup**: `[nabu]` repo now prioritizes over upstream mirrors to prevent version conflict warnings
- **Package Changelogs**: Terminal highlights during `pacman -Syu` and native query support (`pacman -Qc`)
- **Kernel Backup Cleaner**: Added `nabu-kclean` tool to safely clean up old backup UKIs and module trees (*.old) created during kernel updates

### Known issues
- Audio crackling at full volume
- Camera image processing not on par with Android (no Qualcomm ISP tuning)

---

## [Build 2026-09-24]

### Kernel side
- Kernel upgraded to **6.14.11-10** (merged `6.14` branch: MIDI, suspend/wake, VPU, NTFS3, Bluetooth audio fixes)
- Kernel + headers shipped in image — dkms rebuilds modules on-device (self-healing)
- UKI auto-regenerated on kernel install/upgrade (`uki-regenerate`, keeps previous known-good)

### User space side
- DisplayLink out of the box: `dkms`, `evdi-dkms`, `displaylink` pre-installed, `displaylink.service` enabled (atomic + non-atomic installers)
- Flashlight/torch app (`nabu-torch`) with intensity control pre-installed on GNOME + Plasma images
- Installer default kernel version moved to `6.14.11-10`

### Known issues
- Auto-rotation (accelerometer) stops working after sleep — resume fix planned (`nabu-sensors-recover`)
- Audio crackling at full volume
- Camera image processing not on par with Android (no Qualcomm ISP tuning)
