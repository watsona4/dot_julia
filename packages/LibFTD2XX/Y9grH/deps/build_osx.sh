#!/bin/bash

# Mount the drivers
MOUNT_POINT=$(hdiutil attach -noautoopen "./usr/downloads/D2XX1.4.4.dmg" | egrep 'Volumes' | grep -o "/Volumes/.*")

# Copy driver contents to lib directory
`cp -r "$MOUNT_POINT/D2XX/" "./usr/lib"`

# Detach and exit
hdiutil detach "$MOUNT_POINT"