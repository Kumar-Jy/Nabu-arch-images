# Changelog - Arch Linux ARM for Xiaomi Pad 5 (nabu)

All notable changes to the `nabu` Arch Linux ARM disk images, installer packages, and hardware integration are documented in this file.

---

## [Next Build] - 2026-09-24

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

---

## [Unreleased / Upcoming Build] - 2026-09-18

### 📸 Camera & Computational Photography

- **Upgraded Camera Studio to v1.0.5**:

  - **Live Pro Tuning HUD**: Added an on-screen, low-profile floating HUD overlay above the shutter button allowing live adjustment of Exposure Bias (`EV`), White Balance Tint (`Green ↔ Magenta`), Contrast, Vibrance, and Hardware Sharpness with live viewfinder preview.

  - **Top Bar Resolution Popover**: Added a quick resolution dropdown pill button (`13 MP 4:3`, `8 MP 4:3`, `3.2 MP Fast Native`, `4K UHD`, `1080p FHD`, `1:1 Square`) that automatically adapts to rear vs. front camera sensor maximums.

  - **In-App Photo Viewer**: Added `PhotoViewerDialog` with photo metadata inspection (resolution, file size, date), deletion, and quick-open in default image viewer via double-tap or long-press.

  - **Sensor Native 4:3 Stream**: Switched GStreamer live stream to native 4:3 sensor mode (`2048x1536`) to eliminate 16:9 cropping and maximize light capture in low-light conditions.

  - **Sensor Color Neutralization**: Added adaptive white balance color normalization in the capture worker and neutralized uncalibrated Qualcomm color correction matrices to eliminate the greenish fog and bluish tint.

  - **UI Glitch Fixes**: Converted resolution and format selectors to native `Adw.ComboRow` to eliminate vertical letter squashing, widened slider mark spacing to prevent overlapping text, and fixed XML entity parsing in preferences headers.

### 🚀 Boot & Kernel Recovery

- **Reliable UKI Generation (`uki-regenerate`)**:

  - Rewrote kernel resolution logic to query pacman module ownership, preventing stale `.old`/`.safe` module backup directories from hijacking kernel version detection.

  - Added atomic UKI preservation: `arch-linux-nabu-old.efi` is only updated upon verified build success, ensuring the previous known-good kernel always remains bootable in rEFInd if an update fails.

  - Integrated `nabu-boot-tools` providing automated `nabu-boot-repair` and the `/usr/share/libalpm/hooks/90-linux-nabu.uki.hook` pacman hook for automatic UKI rebuilding on kernel upgrades.

  - Ensured persistent DeviceTree configuration in `/etc/kernel/uki.conf` and `acpi=off` in kernel command-line parameters.

### 🖥️ Desktop & Display Manager

- **Plasma Display Manager (`sddm-nabu`)**:

  - Replaced generic SDDM setup with `sddm-nabu`.

  - Enabled virtual on-screen keyboard (`maliit-keyboard`) on the SDDM greeter and lockscreen for seamless password entry without physical keyboard attachment.

- **Display Scaling**:

  - Default Plasma Wayland display scale configured to **175%**, providing ideal touch target sizes and text readability on the 2.5K 120Hz display.

- **GNOME Refinements**:

  - Removed redundant `nabu-autobrightness` service on GNOME images to prevent conflicts with GNOME's native `gsd-power` ambient light sensor handling.

- **Default Browser**:

  - Replaced Google Chrome and Snapshot with `firefox` as the default pre-installed browser with native Wayland touch gestures.

- **Pre-installed Tablet Utilities**:

  - Pre-installed `oskb` (on-screen keyboard toggle button), `system-monitor` (tablet hardware monitor), and `ntfs-3g` (read/write access to Windows partition on dual/triple boot setups).

### 🎬 Hardware Acceleration & Multimedia

- **Iris/Venus GPU Video Acceleration**:

  - Integrated `iris-vaapi`, `ffmpeg-iris`, and `mpv-iris` for hardware-accelerated video decoding (H.264, HEVC, VP9) offloading CPU workload to the Adreno 640 GPU.

---

## [arch-nabu] - 2026-09-14 (Previous Release)

### Added

- **Base Rootfs & Desktop Flavors**:

  - Initial non-atomic installer builds for **KDE Plasma** and **GNOME** based on Arch Linux ARM `aarch64`.

  - TWRP-flashable installer zip packaging (`arch-nabu-installer-plasma.zip`, `arch-nabu-installer-gnome.zip`, `nabu-arch-rEFInd.zip`).

- **Hardware Enablement**:

  - Linux kernel `6.14.11` tree with Qualcomm Snapdragon 860 (`sm8150-v2`) platform support.

  - 120Hz refresh rate on Novatek NT36523 2560x1600 panel.

  - 10-point capacitive multi-touch out of the box.

  - Adreno 640 3D GPU acceleration via Mesa Freedreno and Turnip Vulkan driver.

  - Quad stereo speaker audio via Cirrus Logic CS35L41 amplifiers with ALSA UCM and PipeWire.

  - Wi-Fi 5 and Bluetooth 5.0 support via Qualcomm WCN3990 with persistent MAC address daemon (`nabu-pmac`).

  - SLPI/SSC accelerometer and gyroscope sensors via FastRPC and `iio-sensor-proxy`.

  - Screen auto-rotation daemon (`nabu-tablet-mode`).

  - Xiaomi Smart Pen stylus input support with 4096 pressure levels and dual barrel buttons.

  - Magnetic pogo-pin keyboard cover support.

  - Battery telemetry and USB-PD/QC charging.

  - Dual rear LED flash/torch support.

### Known Limitations in 2026-09-14 Release (Resolved in Upcoming Build)

- Plasma lockscreen required physical keyboard (resolved with `sddm-nabu` virtual keyboard).

- Viewfinder and captured photos suffered from sensor green haze / blue cast (resolved with adaptive AWB and calibrated sensor matrices).

- Camera app relied on external gallery (resolved with in-app `PhotoViewerDialog`).

- UKI regeneration could select older backup kernels if present (resolved with package-based kernel resolution).