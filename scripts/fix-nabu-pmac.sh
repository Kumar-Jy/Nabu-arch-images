#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

mkdir -p /etc/systemd/network
cat > /etc/systemd/network/10-wlan.link <<'EOF'
[Match]
OriginalName=wlan*

[Link]
Name=wlan0
EOF
echo "Wrote /etc/systemd/network/10-wlan.link"

cat > /usr/local/bin/nabu-pmac-set <<'EOF'
#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

serial=$(cat /sys/class/dmi/id/board_serial 2>/dev/null || echo "")
if [ -z "$serial" ]; then
  echo "Board serial not found, aborting."
  exit 1
fi

hash=$(echo -n "$serial" | sha256sum | awk '{print $1}')
mac_raw=${hash:0:12}
mac_bytes=($(echo $mac_raw | sed 's/\(..\)/\1 /g'))
first_byte=${mac_bytes[0]}
first_byte_dec=$((16#$first_byte))
first_byte_dec=$(( (first_byte_dec & 0xFC) | 0x02 ))
first_byte_hex=$(printf '%02x' $first_byte_dec)
mac="${first_byte_hex}:${mac_bytes[1]}:${mac_bytes[2]}:${mac_bytes[3]}:${mac_bytes[4]}:${mac_bytes[5]}"

dev=""
n=0
while [ -z "$dev" ]; do
  n=$((n+1))
  if [ $n -ge 90 ]; then
    echo "No wireless interface found within 90s, aborting." >&2
    exit 1
  fi
  dev=$(ls /sys/class/net 2>/dev/null | grep -E '^wl' | head -n 1 || echo "")
  [ -n "$dev" ] && break
  sleep 1
done

ip link set dev "$dev" down 2>/dev/null || true
ip link set dev "$dev" address "$mac"
ip link set dev "$dev" up

echo "Serial: $serial"
echo "Set WiFi MAC ($dev): $mac"
EOF
chmod 755 /usr/local/bin/nabu-pmac-set
echo "Updated /usr/local/bin/nabu-pmac-set (bounded wait)"

install -d /etc/systemd/system/nabu-pmac.service.d
cat > /etc/systemd/system/nabu-pmac.service.d/10-ordering.conf <<'EOF'
[Unit]
Wants=network-pre.target
Before=network-pre.target
EOF
echo "Wrote /etc/systemd/system/nabu-pmac.service.d/10-ordering.conf"

systemctl daemon-reload
systemctl enable nabu-pmac

echo
echo "nabu-pmac hotfix applied."
echo "Reboot for the interface rename and boot ordering to take effect."
echo "After reboot, verify with: ip link show wlan0"
