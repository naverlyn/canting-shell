#!/usr/bin/env bash
# Lock the session using Quickshell IPC, with fallback to hyprlock.

if command -v qs >/dev/null 2>&1; then
    if qs ipc call lockscreen lock 2>/dev/null; then
        exit 0
    fi
elif command -v quickshell >/dev/null 2>&1; then
    if quickshell ipc call lockscreen lock 2>/dev/null; then
        exit 0
    fi
fi

# Fallback: if quickshell is not running or IPC fails, launch hyprlock
if command -v hyprlock >/dev/null 2>&1; then
    exec hyprlock
fi

exit 1

