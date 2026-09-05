#!/bin/sh
case "$1/$2" in
    post/*)
        /usr/bin/killall -USR1 nabu-tablet-mode 2>/dev/null || true
        ;;
esac
