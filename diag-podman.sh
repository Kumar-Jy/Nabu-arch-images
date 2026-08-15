#!/usr/bin/env bash
# bootc spawns us as its "external container tool". For the "env" probe it
# parses our stdout as JSON, so we must not print anything to stdout.
rm -f /dev/shm/libpod_lock* 2>/dev/null || true
exec podman "$@"