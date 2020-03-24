#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide

STATUS="asd"

# Information for Partitioning
SWAP="8"

abort() {
    echo -e "\n${STATUS}"
    echo "Installation process aborted."
    exit -1
}

# Pre-installation

# Update the system clock
echo -n "Synchronizing system clock..."

#STATUS=$(timedatectl set-ntp true)
if [ -z $STATUS ]; then
   echo "DONE"
else
    abort
fi


