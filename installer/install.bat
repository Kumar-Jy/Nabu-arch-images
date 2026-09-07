@echo off
:: Check if font has already been set because if not then it will loop
if "%1" neq "nofont" (
    :: CMD font size set to approx. 34 in hex 0x00220000
    reg add "HKCU\Console" /v FontSize /t REG_DWORD /d 0x00220000 /f >nul 2>&1
	:: maximize CMD window
    reg add "HKCU\Console" /v WindowSize /t REG_DWORD /d 0x00190050 /f >nul 2>&1
    reg add "HKCU\Console" /v WindowPosition /t REG_DWORD /d 0x00000000 /f >nul 2>&1
    :: re-run the batch file with a flag so it doesnt loop
    start "" /wait cmd /c "%~f0" nofont
    exit /b
)

setlocal enabledelayedexpansion
echo Copyright (C) 2025-26 https://github.com/Kumar-jy, https://github.com/ArKT-7
:: Set console max char to 99 (as best for 34 font size) so the text can be wrapped to next line
::mode con: cols=99
:: idk but why wraping needed
mode 800

set espname=ESPNABU
set devicename=XIAOMI PAD 5
set secureboot=FALSE

echo(
echo ============================================================
echo            Welcome to WinInstaller for %devicename%
echo ============================================================
echo(
echo Running CHKDSK on the current drive...
chkdsk %~d0 /F /X
echo CHKDSK complete.

echo(
echo ============================================================
echo             Checking for Windows installation...
echo ============================================================
echo(

rem Check if Windows is already installed
if exist "%~d0\Windows\explorer.exe" (
    echo Windows is already installed.
    goto formatAndAssign
) else (
    echo windows not installed
    goto fail
)

:formatAndAssign
echo ============================================================
echo           Formatting and assigning drive letter to bootloader
echo ============================================================
echo(

for /f "tokens=2 delims= " %%f in ('echo list volume ^| diskpart ^| findstr /i "FAT32" ^| findstr /i "PE"') do (
	set volumeNumber=%%f
	goto volFound
)

echo No FAT32 PE volume found. Searching for %espname%...
for /f "tokens=2 delims= " %%f in ('echo list volume ^| diskpart ^| findstr /i "FAT32" ^| findstr /i "%espname%"') do (
    set volumeNumber=%%f
    goto volFound
)

echo No FAT32 ESP or PE volume found. & goto fail

:volFound
echo Found FAT32 volume with ESP or PE, Volume Number %volumeNumber%

rem Format the volume, assign the drive letter S, and label it accordingly
(
    echo select volume %volumeNumber%
    echo format fs=fat32 quick label=%espname%
    echo assign letter=S
) | diskpart

echo(
echo ============================================================
echo           Creating bootloader files...
echo ============================================================
echo(

call :addbootentry %~d0 || goto fail

echo(
echo ==========================================================
echo Installation completed. Rebooting into Windows in 5 seconds.
echo Script written by @Kumar_Jy, and @bibarub
echo ==========================================================
echo(
echo ==========================================================
echo           Cleaning installation files........
echo ==========================================================
rmdir /s /q "%~dp0" & shutdown /r /t 5
exit /b

:fail
echo Take a picture of the error, force reboot and ask for help on Telegram @wininstaller or @woahelperchat
pause
exit /b 1
:addbootentry
bcdboot %~1\Windows /s S: /f UEFI || exit /b 1
cd /d "%~d0\efi" || exit /b 1
if exist "S:\EFI\Boot" rmdir /s /q "S:\EFI\Boot"
robocopy "." "S:\EFI" /E /XC /XN /XO /R:0 /W:0 >nul 2>&1
if %ERRORLEVEL% GEQ 8 exit /b 1

if not "%secureboot%"=="TRUE" (
    bcdedit /store S:\EFI\Microsoft\Boot\BCD /set {default} testsigning on || (echo Failed to enable test signing. & exit /b 1)
    bcdedit /store S:\EFI\Microsoft\Boot\BCD /set {default} nointegritychecks on || (echo Failed to disable integrity checks. & exit /b 1)
    bcdedit /store S:\EFI\Microsoft\Boot\BCD /set {default} recoveryenabled no || (echo Failed to disable recovery. & exit /b 1)
)

exit /b
:indexlookup
for /f "tokens=2 delims=: " %%a in ('dism /Get-WimInfo /WimFile:%imageFile% ^| findstr /i /c:"Index :"') do (
    set currentIndex=%%a
    for /f "delims=" %%b in ('dism /Get-WimInfo /WimFile:%imageFile% /Index:%%a ^| findstr /i /c:"Name : %~1"') do (
        set index=%%a
		echo Index value %%a found for %~1
        exit /b
    )
)
echo %~1 not found in the image file.
exit /b 1