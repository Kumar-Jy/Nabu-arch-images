# Arch Linux ARM Installer for Xiaomi Pad 5 (nabu)
![Arch Linux Arm on the Xiaomi Pad 5 (nabu)](nabu_alarm.jpg)

---

## Requirements

- Xiaomi Pad 5 (nabu)
- Unlocked bootloader
- [TWRP](https://github.com/Kumar-Jy/twrp_device_xiaomi_nabu/releases/tag/mod-hybrid) custom recovery
- Installer zip from [Releases](https://github.com/Kumar-Jy/Nabu-arch-images/releases)

---

## Partition Layout

The installer expects the following GPT partitions (already present from a Windows/dual-boot setup):

| Partition | Block Device | Format | Purpose |
|-----------|-------------|--------|---------|
| `boot` | `/dev/block/bootdevice/by-name/boot` | Android boot | Patched with DBKP + UEFI payload |
| `esp` | `/dev/block/by-name/esp` | FAT32 | EFI System Partition (rEFInd, UKI, Windows EFI) |
| `win` | `/dev/block/by-name/win` | NTFS | Windows installation |
| `linux` | `/dev/block/by-name/linux` | ext4 | Arch Linux rootfs |

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
   - `alarm-nabu-installer-plasma.zip` — Plasma Desktop
   - `alarm-nabu-installer-gnome.zip` — GNOME Desktop

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

## Credit & Thanks

| Component | Description | Author |
| :--- | :--- | :--- |
| Arch-Installer | Arch Installer script | [Kumar-Jy](https://github.com/Kumar-Jy) |
| RootFS & EFI | Arch RootFS and kernel | [Kumar-Jy](https://github.com/Kumar-Jy), [rodriguest](https://github.com/rodriguezst), [Timofey](https://github.com/timoxa0) |
| DBKP | DualBoot kernel patcher and UEFI payload | [rodriguest](https://github.com/rodriguezst), [remtrik](https://github.com/remtrik), [map220v](https://github.com/map220v), [Project Aloha](https://github.com/Project-Aloha) |

## See Also

- [postmarketOS](https://wiki.postmarketos.org/wiki/Xiaomi_Pad_5_%28xiaomi-nabu%29) — pmOS for nabu
- [pocketblue](https://github.com/pocketblue/pocketblue) — Fedora Silverblue for nabu
- [nabu-fedora](https://github.com/jhuang6451/nabu_fedora) — Fedora for nabu
- [nabu-alarm](https://github.com/nabu-alarm/) — Arch Linux ARM for nabu (EOL)
- [Xiaomi-Nabu](https://github.com/TheMojoMan/Xiaomi-Nabu) — Ubuntu for nabu
