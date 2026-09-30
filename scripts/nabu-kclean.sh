#!/usr/bin/env bash
#
# nabu-kclean.sh - Safely clean up old/backed-up kernel versions,
# module trees (*.old), and backup UKIs (*-old.efi) on Xiaomi Pad 5 (nabu).
#
set -euo pipefail

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[1;31mError:\e[0m This script must be run as root (e.g. sudo ./nabu-kclean.sh)." >&2
    exit 1
fi

DRY_RUN=0
ASSUME_YES=0

usage() {
    cat << 'EOF'
Usage: sudo ./nabu-kclean.sh [OPTIONS]

Safely cleans up backed-up kernel modules (*.old), dangling module symlinks,
and backup UKIs (*-old.efi) generated during kernel upgrades on Xiaomi Pad 5.

Options:
  -n, --dry-run    Show what would be removed without deleting anything
  -y, --yes        Automatically proceed with removal without confirmation
  -h, --help       Show this help message

Protected items (never removed):
  * Currently running kernel (uname -r)
  * Currently active kernel tracked by pacman and boot symlinks
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

echo -e "\e[1;34m=== Nabu Kernel Backup Cleaner ===\e[0m\n"

RUNNING_KVER="$(uname -r)"
echo -e "\e[1;34m::\e[0m \e[1mRunning kernel:\e[0m \e[1;32m${RUNNING_KVER}\e[0m"

# Identify the currently installed/active package kernel version
ACTIVE_KVER=""
if [ -L "/boot/vmlinuz-linux-nabu" ]; then
    TARGET="$(readlink -f /boot/vmlinuz-linux-nabu 2>/dev/null || true)"
    ACTIVE_KVER="${TARGET##*/vmlinuz-}"
fi
if [ -z "$ACTIVE_KVER" ] && command -v pacman >/dev/null 2>&1; then
    ACTIVE_KVER="$(pacman -Q linux-nabu 2>/dev/null | awk '{print $2}' || true)"
fi
if [ -n "$ACTIVE_KVER" ] && [ "$ACTIVE_KVER" != "$RUNNING_KVER" ]; then
    echo -e "\e[1;34m::\e[0m \e[1mActive installed kernel:\e[0m \e[1;32m${ACTIVE_KVER}\e[0m"
fi

TO_REMOVE=()
TOTAL_BYTES=0

# 1. Inspect /usr/lib/modules for *.old and *.safe directories
if [ -d "/usr/lib/modules" ]; then
    for item in /usr/lib/modules/*.old /usr/lib/modules/*.safe; do
        [ -e "$item" ] || continue
        TO_REMOVE+=("$item")
    done

    # Check for dangling or superseded symlinks in /usr/lib/modules
    for item in /usr/lib/modules/*; do
        if [ -L "$item" ]; then
            target="$(readlink "$item" || true)"
            case "$target" in
                *.old|*.safe)
                    TO_REMOVE+=("$item")
                    ;;
                *)
                    if [ ! -e "$item" ]; then
                        TO_REMOVE+=("$item")
                    fi
                    ;;
            esac
        fi
    done
fi

# 2. Inspect /boot/efi for backup UKIs
ESP_DIR="/boot/efi"
if mountpoint -q "$ESP_DIR" 2>/dev/null || [ -d "$ESP_DIR/EFI/arch" ]; then
    for item in "$ESP_DIR/EFI/arch/"*-old.efi "$ESP_DIR/EFI/arch/"*.old.efi; do
        [ -f "$item" ] || continue
        TO_REMOVE+=("$item")
    done
fi

# 3. Inspect /boot for orphaned kernel/dtb files not matching running or active
for f in /boot/vmlinuz-* /boot/vmlinux-* /boot/dtb-*; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in
        vmlinuz-linux-nabu|vmlinux-linux-nabu|dtb-linux-nabu) continue ;;
    esac
    kver="${base#vmlinuz-}"
    kver="${kver#vmlinux-}"
    kver="${kver#dtb-}"
    if [ "$kver" != "$RUNNING_KVER" ] && [ "$kver" != "$ACTIVE_KVER" ]; then
        is_target=0
        for l in /boot/*-linux-nabu; do
            if [ -L "$l" ] && [ "$(readlink -f "$l" 2>/dev/null)" = "$f" ]; then
                is_target=1
                break
            fi
        done
        if [ "$is_target" -eq 0 ]; then
            TO_REMOVE+=("$f")
        fi
    fi
done

if [ ${#TO_REMOVE[@]} -eq 0 ]; then
    echo -e "\n\e[1;32m::\e[0m No backed-up or orphaned kernel files found. System is clean!"
    exit 0
fi

# Sort and deduplicate items to remove
UNIQUE_ITEMS=($(printf "%s\n" "${TO_REMOVE[@]}" | sort -u))

echo -e "\n\e[1;33m::\e[0m \e[1mFound ${#UNIQUE_ITEMS[@]} backed-up / orphaned kernel items to clean:\e[0m"
for item in "${UNIQUE_ITEMS[@]}"; do
    if [ -e "$item" ] || [ -L "$item" ]; then
        size="$(du -sh "$item" 2>/dev/null | awk '{print $1}' || echo "0")"
        bytes="$(du -sb "$item" 2>/dev/null | awk '{print $1}' || echo "0")"
        TOTAL_BYTES=$((TOTAL_BYTES + bytes))
        echo "   - [${size}] $item"
    fi
done

TOTAL_HUMAN="$(numfmt --to=iec-i --suffix=B "$TOTAL_BYTES" 2>/dev/null || echo "$((TOTAL_BYTES / 1024 / 1024)) MiB")"
echo -e "\n\e[1;34m::\e[0m Total space to be reclaimed: \e[1;32m${TOTAL_HUMAN}\e[0m"

if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "\n\e[1;33m[Dry Run]\e[0m No files were removed."
    exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
    read -r -p "Do you want to proceed with removal? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) ;;
        *)
            echo "Operation cancelled."
            exit 0
            ;;
    esac
fi

echo -e "\n\e[1;34m::\e[0m Cleaning backed-up kernel items..."
for item in "${UNIQUE_ITEMS[@]}"; do
    if [ -L "$item" ] || [ -f "$item" ]; then
        rm -f "$item"
        echo "   Removed: $item"
    elif [ -d "$item" ]; then
        rm -rf "$item"
        echo "   Removed: $item"
    fi
done

echo -e "\n\e[1;32m::\e[0m Cleanup completed successfully! Reclaimed \e[1;32m${TOTAL_HUMAN}\e[0m of disk space."
