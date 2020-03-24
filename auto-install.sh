#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide

# Common variable for storing return values of certain commands
STATUS=""

# Information for Partitioning
SWAP="8G"

abort() {
    echo -e "\n${STATUS}"
    echo "Installation process aborted."
    exit -1
}

# Pre-installation

# Update the system clock
echo -n "Synchronizing system clock..."

STATUS=$(timedatectl set-ntp true)
if [ -z $STATUS ]; then
   echo "DONE"
else
    abort
fi

# Partition the disk
echo -n "Partition the disk..."

sfdisk /dev/sda << EOF
    , ${SWAP}, S
    , , , *
EOF

STATUS=$(sfdisk -V /dev/sda)
if [ "$STATUS" = "/dev/sda:" ]; then
    echo "DONE"
else
    abort
fi
