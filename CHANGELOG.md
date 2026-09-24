# Changelog - Arch Linux ARM for Xiaomi Pad 5 (nabu)

All notable changes to the `nabu` Arch Linux ARM disk images, installer packages, and hardware integration are documented in this file.

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