# Arch Linux ARM Installer for Xiaomi Pad 5 (nabu)
![Arch Linux Arm on the Xiaomi Pad 5 (nabu)](nabu_alarm.jpg)

---

## Table of Contents

- [Requirements](#requirements)
- [Hardware Support Status](#hardware-support-status)
- [Installation](#installation)
- [Updating the Kernel](#updating-the-kernel)
- [Troubleshooting](#troubleshooting)
- [Credit & Thanks](#credit--thanks)
- [See Also](#see-also)

---

## Requirements

- Xiaomi Pad 5 (nabu)
- Unlocked bootloader
- [TWRP](https://github.com/Kumar-Jy/twrp_device_xiaomi_nabu/releases/tag/mod-hybrid) custom recovery
- Installer zip from [Releases](https://github.com/Kumar-Jy/Nabu-arch-images/releases/tag/arch-nabu)

---

## Hardware Support Status

| Category | Hardware Feature | Status | Notes |
| :--- | :--- | :---: | :--- |
| **Display** | 2.5K WQHD+ LCD (2560x1600 @ 120Hz) | ✅ Working | Novatek NT36523 panel driver, smooth 120Hz refresh rate |
| **Touch** | Capacitive Multi-touch | ✅ Working | 10-point multi-touch supported out of the box |
| **Graphics** | 3D GPU Acceleration (Adreno 640) | ✅ Working | Mesa Turnip (Vulkan 1.3) & Freedreno (OpenGL 4.6) |
| **Video Decode** | Hardware Video Acceleration | ✅ Working | Iris/Venus V4L2 stateful decode (H.264, HEVC, VP9) |
| **Audio** | Quad Stereo Speakers | ✅ Working | ALSA UCM + PipeWire (WCD9340 + WSA8810 smart amps) |
| **Microphone** | Built-in Mic Array | ✅ Working | Clear audio recording via PipeWire |
| **Camera (Rear)** | 13MP OmniVision OV13B10 | ✅ Working | `camera-studio` / libcamera with VCM autofocus |
| **Camera (Front)** | 8MP OmniVision OV8856 | ✅ Working | `camera-studio` with upright orientation correction |
| **Flash / Torch** | Dual Rear LED Flash | ⚠️ Partial | Controlled via sysfs flash node |
| **Wireless** | Wi-Fi 5 (802.11ac 2.4/5GHz) | ✅ Working | Qualcomm WCN3990 via NetworkManager |
| **Bluetooth** | Bluetooth 5.0 | ✅ Working | Qualcomm WCN3990 via BlueZ |
| **Sensors** | Accelerometer & Gyroscope | ✅ Working | SLPI/SSC via FastRPC & `iio-sensor-proxy` |
| **Screen Rotation** | Automatic Screen Rotation | ✅ Working | Handled via `nabu-tablet-mode` daemon |
| **Auto-Brightness** | Ambient Light Sensor (ALS) | ✅ Working | Native `gsd-power` on GNOME, `nabu-autobrightness` on Plasma |
| **Touch Keyboard** | Virtual Touch Keyboard | ✅ Working | Built-in `oskb` with resize presets & arrow navigation |
| **Stylus** | Xiaomi Smart Pen | ✅ Working | Stylus tap and pointer events |
| **Accessories** | Magnetic Pogo-Pin Keyboard Cover | ✅ Working | Instant physical typing via serial pogo connector |
| **Battery & Power** | Battery Telemetry & Charging | ✅ Working | Battery percentage via `upower-nncc`, USB-PD / QC charging |
| **Sleep** | Suspend & Resume | ✅ Working | S2idle sleep with post-resume sensor recovery |
| **USB** | USB Type-C 2.0 & OTG | ✅ Working | Flash drives, mice, keyboards, hubs supported |
| **External Display** | USB DisplayLink Output | ✅ Working | Supported with DisplayLink docks (`displaylink` + `evdi`) |
| **External Display** | USB-C DisplayPort Alt-Mode | ❌ Not Supported | Hardware limitation (SoC USB lines lack DP routing) |
| **DRM** | Widevine L1 (HD Streaming) | ❌ Not Supported | Widevine L3 software works; L1 requires Android TEE |

---

## Installation

### Creating Partitions (if not already present)

If your device doesn't have the required `esp` and `linux` partitions, create them first:

1. **Boot into TWRP** from your PC:
   ```bash
   fastboot boot twrp.img
   ```

2. **Open TWRP Terminal**: In TWRP, go to **Advanced > Terminal**

3. **Run the partition tool**:
   ```bash
   partition
   ```
   Follow the on-screen instructions to create the `win` (optional), `linux` and `esp` partitions.

4. **Reboot back into TWRP** after partitioning: Go to **Reboot > Recovery**

5. Proceed to the installation steps below.

### Triple Boot (Windows + Android + Linux)

1. **Install Windows first** — Set up Windows on the `win` partition
2. **Return to Android** — Boot back into Android to ensure it's working
3. **Flash the Linux installer** — Boot into TWRP and flash the Arch Linux installer zip
4. **Reboot** — rEFInd will show all three boot options (Windows, Android, Linux)

### Arch Linux Install (Single Boot or Dual Boot)

1. **Download** the latest installer from [Releases](https://github.com/Kumar-Jy/Nabu-arch-images/releases):
   - `arch-nabu-installer-plasma.zip` — Plasma Desktop
   - `arch-nabu-installer-gnome.zip` — GNOME Desktop

2. **Boot into TWRP**: Power off the tablet, hold **Power + Volume Up**

3. **Flash the installer zip**: In TWRP, tap **Install**, navigate to the zip, swipe to confirm

4. **What the installer does**:
   - Formats `/dev/block/by-name/linux` with ext4
   - Extracts the rootfs image onto the partition
   - Patches the `boot` partition with DBKP + UEFI payload
   - Sets up ESP with rEFInd and the Unified Kernel Image

5. **Reboot**: Select **Reboot > System**

6. **Default credentials**: `user` / `123456`

### Dual/Triple Boot with Android/Windows

- The `boot` partition is patched with DualBootKernelPatcher + UEFI payload
- On first UEFI boot, `installer/install.bat` runs in WinPE to reconfigure Windows BCD
- rEFInd provides a boot menu to choose between Android, Arch Linux and Windows

---

## Updating the Kernel

### Official update (from the nabu repository)

```bash
sudo pacman -Syu
```

### Local / custom (non-official) kernel update

If you built your own kernel package:

```bash
# 1. Build your own package (bump pkgver / pkgrel on EVERY build!)
makepkg
# 2. Install it directly
sudo pacman -U linux-nabu-<version>-aarch64.pkg.tar.xz
```

> pacman decides "is this an update?" using only `pkgver`/`pkgrel`, never the kernel
> version string. If those don't change, pacman reports *"up to date"* and skips the
> install, so the UKI won't be regenerated. Always bump `pkgver` (or `pkgrel`) for
> each new build.

The UKI is regenerated automatically by the pacman hook for any package named
`linux-nabu*`, including custom builds. To force a rebuild manually:

```bash
sudo /usr/libexec/nabu/uki-regenerate
```

### Offline Kernel Install / Recovery via TWRP

If Linux cannot boot or you want to install/update a kernel package (`.pkg.tar.xz`) completely offline using TWRP:

**1. Push the package to TWRP's `/tmp/` directory:**

```bash
adb push linux-nabu-6.xx.xx-aarch64.pkg.tar.xz /tmp/
```

**2. Open an ADB shell, mount the partitions, and install inside the chroot:**

```bash
adb shell

# Mount rootfs, EFI partition, and virtual filesystems
mount /dev/block/by-name/linux /linux
mount /dev/block/by-name/esp /linux/boot/efi
mount -t proc proc /linux/proc
mount -t sysfs sys /linux/sys
mount --bind /dev /linux/dev

# Copy package and install inside chroot
cp /tmp/linux-nabu-*.pkg.tar.xz /linux/tmp/
env -i PATH=/usr/bin:/usr/sbin:/bin:/sbin TMPDIR=/tmp chroot /linux pacman -U /tmp/linux-nabu-6.xx.xx-aarch64.pkg.tar.xz
```

**3. Unmount and reboot:**

```bash
umount /linux/boot/efi /linux/dev /linux/sys /linux/proc /linux
reboot
```

---

## Troubleshooting

For solutions to common issues (such as boot loops after updates, Wi-Fi MAC address fixes, or recovering from a locked emergency console), see the [Troubleshooting Guide](TROUBLESHOOTING.md).

---

## Credit & Thanks

| Component | Description | Author |
| :--- | :--- | :--- |
| Arch-Installer | Arch Installer script | [Kumar-Jy](https://github.com/Kumar-Jy) |
| RootFS & EFI | Arch RootFS and kernel | [Kumar-Jy](https://github.com/Kumar-Jy), [rodriguest](https://github.com/rodriguezst), [TwinbornPlate75](https://github.com/TwinbornPlate75), [Timofey](https://github.com/timoxa0) |
| DBKP | DualBoot kernel patcher and UEFI payload | [rodriguest](https://github.com/rodriguezst), [remtrik](https://github.com/remtrik), [map220v](https://github.com/map220v), [Project Aloha](https://github.com/Project-Aloha) |

## See Also

- [postmarketOS](https://wiki.postmarketos.org/wiki/Xiaomi_Pad_5_%28xiaomi-nabu%29) — pmOS for nabu
- [pocketblue](https://github.com/pocketblue/pocketblue) — Fedora Silverblue for nabu
- [nabu-fedora](https://github.com/jhuang6451/nabu_fedora) — Fedora for nabu
- [nabu-alarm](https://github.com/nabu-alarm/) — Arch Linux ARM for nabu (EOL)
- [Xiaomi-Nabu](https://github.com/TheMojoMan/Xiaomi-Nabu) — Ubuntu for nabu
