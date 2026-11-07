@echo off
setlocal enabledelayedexpansion

set "DIR=%~dp0"
if exist "%DIR%images\rootfs.img" (
    set "IMAGES_DIR=%DIR%images\"
) else if exist "%DIR%rootfs.img" (
    set "IMAGES_DIR=%DIR%"
) else (
    echo Error: images directory not found at %DIR%images
    exit /b 1
)

set "ROOTFS=%IMAGES_DIR%rootfs.img"
set "ESP=%IMAGES_DIR%esp.img"
set "UEFI=%IMAGES_DIR%alohauefi.img"

if not exist "%ROOTFS%" (
    echo Error: rootfs image not found at %ROOTFS%
    exit /b 1
)
if not exist "%ESP%" (
    echo Error: esp image not found at %ESP%
    exit /b 1
)

echo Checking connected device...
fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *nabu" >nul || (
    echo Error: Device mismatch ^(expected nabu^)
    exit /b 1
)

set "ROOT_PART=userdata"
set "ESP_PART=cust"

fastboot %* getvar partition-size:linux 2>&1 | findstr /c:"partition-size:linux:" >nul
if not errorlevel 1 (
    fastboot %* getvar partition-size:esp 2>&1 | findstr /c:"partition-size:esp:" >nul
    if not errorlevel 1 (
        echo Detected dual/multi-boot partition layout ^(linux + esp^)
        set "ROOT_PART=linux"
        set "ESP_PART=esp"
    )
)

if "%ROOT_PART%"=="userdata" (
    echo Using single-boot partition layout ^(userdata + cust^)
)

if exist "%UEFI%" (
    echo Flashing Aloha UEFI to boot_ab...
    fastboot %* flash boot_ab "%UEFI%" || (
        echo Flashing per-slot boot_a and boot_b...
        fastboot %* flash boot_a "%UEFI%" || exit /b 1
        fastboot %* flash boot_b "%UEFI%" || exit /b 1
    )
) else (
    echo Note: alohauefi.img not found, skipping boot partition flash.
)

echo Erasing %ROOT_PART% and %ESP_PART%...
fastboot %* erase %ROOT_PART% || (echo Error erasing %ROOT_PART% & exit /b 1)
fastboot %* erase %ESP_PART% || (echo Error erasing %ESP_PART% & exit /b 1)

echo Flashing rootfs to %ROOT_PART%...
fastboot %* flash %ROOT_PART% "%ROOTFS%" || (echo Error flashing rootfs & exit /b 1)

echo Flashing ESP to %ESP_PART%...
fastboot %* flash %ESP_PART% "%ESP%" || (echo Error flashing ESP & exit /b 1)

echo Flashing completed successfully! Rebooting...
fastboot %* reboot || (echo Error rebooting & exit /b 1)
