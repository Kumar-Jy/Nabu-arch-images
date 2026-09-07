# Flashable_UEFI_Installer

[DualBootKernelPatcher](https://github.com/Project-Aloha/DualBootKernelPatcher) UEFI A/B Installer Zip Template

Forked and modified from [Flashable_UEFI_Installer by MollySophia](https://github.com/MollySophia/Flashable_UEFI_Installer) and [twrp_abtemplate by osm0sis](https://github.com/osm0sis/twrp_abtemplate).

## Packing How-to:
Add the following files and pack as a Zip file:
- DBKP Binary (Linux-arm64): _DualBootKernelPatcher_
- DBKP ShellCode: _ShellCode.Codename.bin_ from DBKP (e.g. _ShellCode.Nabu.bin_ for Xiaomi Pad 5)
- DBKP Config: _DualBoot.Codename.cfg_ (e.g. _DualBoot.Sm8150.cfg_ for Xiaomi Pad 5)
- UEFI fd file: _CODENAME\_EFI.fd_ (e.g. _SM8150_EFI.fd_ for Xiaomi Pad 5)

## Installation:
Flash the packed Zip file using TWRP or Magisk Manager.