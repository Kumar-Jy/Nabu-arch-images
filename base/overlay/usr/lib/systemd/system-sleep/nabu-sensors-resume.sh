#!/bin/sh
case "$1/$2" in
    pre/*)
        /usr/bin/systemctl stop iio-sensor-proxy 2>/dev/null || true
        ;;
    post/*)
        /usr/bin/systemd-run --no-block /usr/local/bin/nabu-resume-sensors.sh 2>/dev/null || \
            (/usr/local/bin/nabu-resume-sensors.sh >/dev/null 2>&1 &)
        ;;
esac
