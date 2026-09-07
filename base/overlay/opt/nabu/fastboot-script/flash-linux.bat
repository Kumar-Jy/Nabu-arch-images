@echo off
fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *nabu" || echo Missmatching image and device
fastboot %* getvar product 2>&1 | findstr /r /c:"^product: *nabu" || exit /B 1
fastboot %* getvar partition-size:linux 2>&1 | findstr /c:"partition-size:linux:" >nul || echo "Linux partition not found"
fastboot %* getvar partition-size:linux 2>&1 | findstr /c:"partition-size:linux:" >nul || exit /B 1
fastboot %* erase linux || @echo "Erase linux error" && exit /B 1
fastboot %* erase esp || @echo "Erase esp error" && exit /B 1
fastboot %* flash linux %~dp0images\rootfs.img || @echo "Flash rootfs error" && exit /B 1
fastboot %* flash esp %~dp0images\esp.img || @echo "Flash esp error" && exit /B 1
fastboot %* reboot || @echo "Reboot error" && exit /B 1
