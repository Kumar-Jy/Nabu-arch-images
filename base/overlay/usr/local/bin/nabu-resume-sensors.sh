#!/bin/bash
# Nabu post-resume sensor recovery helper

echo "nabu-resume-sensors: Starting post-resume sensor recovery..."

# 1. Wait for SLPI remoteproc to be running (up to 5s)
for i in $(seq 1 50); do
    state=$(cat /sys/class/remoteproc/remoteproc0/state 2>/dev/null)
    if [ "$state" = "running" ]; then
        echo "nabu-resume-sensors: remoteproc0 is running (attempt $i)"
        break
    fi
    sleep 0.1
done

# 2. Wait for hexagonrpcd to finish serving sensor registry files
sleep 1.5

# 3. Ensure iio-sensor-proxy is running and reconnected to SLPI
systemctl restart iio-sensor-proxy 2>/dev/null || true

# 4. Wait for net.hadess.SensorProxy to report HasAccelerometer == true (up to 4s)
has_accel=false
for i in $(seq 1 40); do
    val=$(busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy HasAccelerometer 2>/dev/null || true)
    if echo "$val" | grep -q 'true'; then
        echo "nabu-resume-sensors: HasAccelerometer is true (attempt $i)"
        has_accel=true
        break
    fi
    sleep 0.1
done

if [ "$has_accel" = "false" ]; then
    echo "nabu-resume-sensors: WARNING: HasAccelerometer not true after 4s"
fi

# 5. Settle delay for Mutter/KWin D-Bus name watcher to bind
sleep 0.3

# 6. Pulse SW_TABLET_MODE (0 -> 1) to trigger Mutter/KWin orientation update
echo "nabu-resume-sensors: Pulsing SW_TABLET_MODE for compositor..."
/usr/bin/killall -USR1 nabu-tablet-mode 2>/dev/null || true

echo "nabu-resume-sensors: Recovery complete."
