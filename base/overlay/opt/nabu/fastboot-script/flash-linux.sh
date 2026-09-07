#!/usr/bin/env bash
fastboot "$@" getvar product 2>&1 | grep -q 'product: *nabu' || { echo "Missmatching image and device"; exit 1; }
fastboot "$@" getvar partition-size:linux 2>&1 | grep -q "partition-size:linux:" || { echo "Linux partition not found"; exit 1; }
fastboot "$@" getvar partition-size:esp 2>&1 | grep -q "partition-size:esp:" || { echo "ESP partition not found"; exit 1; }
fastboot "$@" erase linux || { echo "Erase linux error"; exit 1; }
fastboot "$@" erase esp || { echo "Erase esp error"; exit 1; }
DIR="$(cd "$(dirname "$0")" && pwd)"
fastboot "$@" flash linux "$DIR/images/rootfs.img" || { echo "Flash rootfs error"; exit 1; }
fastboot "$@" flash esp "$DIR/images/esp.img" || { echo "Flash esp error"; exit 1; }
fastboot "$@" reboot || { echo "Reboot error"; exit 1; }
