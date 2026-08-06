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

install -d /etc/systemd/system/nabu-pmac.service.d
cat > /etc/systemd/system/nabu-pmac.service.d/10-ordering.conf <<'EOF'
[Unit]
Wants=network-pre.target
Before=network-pre.target
After=sys-subsystem-net-devices-wlan0.device
EOF
echo "Wrote /etc/systemd/system/nabu-pmac.service.d/10-ordering.conf"

systemctl daemon-reload
systemctl enable nabu-pmac

echo
echo "nabu-pmac hotfix applied."
echo "Reboot for the interface rename and boot ordering to take effect."
echo "After reboot, verify with: ip link show wlan0"
