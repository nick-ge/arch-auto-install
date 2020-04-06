#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide

HORIZONTALE="=================================================="
SUBHORIZONTALE="==========================="

# Common variable for storing stderr output of certain commands
ERROR=""

# Util function which gets invoked after every command.
# It checks the given return code and prints the error message and the
# respective return code of the corresponding command.
check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo "ERROR"
        echo "$ERRORTEXT" >&2
        echo "=> Installation process aborted"
        exit $RETURN
    fi
}

echo -e "\n$HORIZONTALE"
echo -e "\t   Arch Linux Installation Script"
echo -e "$HORIZONTALE\n"

echo -ne "Synchronizing system clock...\t\t\t"
ERROR=$(timedatectl set-ntp true 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

# Partitioning of harddrive

./partitioning/partitioning.sh
if [ $? -eq 0 ]; then
    echo -e "=> Partitioning successfully finished\n"
else
    echo "=> Partitioning failed" >&2
    exit 1
fi

echo -ne "Mounting file system to /mnt...\t\t\t"
ERROR=$(mount /dev/sda1 /mnt 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

echo -ne "Downloading current mirrorlist...\t\t"
ERROR=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? "$ERROR"

# Actual Installation

echo -ne "Installing essential packages...\t\t"
ERROR=$(pacstrap /mnt $(cat packagelist) 2>&1 1>/dev/null)
check_returncode $? "$ERROR"

echo -ne "Generating an fstab file...\t\t\t"
ERROR=$(genfstab -U /mnt 2>&1 1>>/mnt/etc/fstab)
check_returncode $? "$ERROR"

# Chrooting
mkdir -p /mnt/root/.local/
cp -r chrooted/ /mnt/root/.local/.
chmod +x /mnt/root/.local/chrooted/*

arch-chroot /mnt /root/.local/chrooted/chrooted.sh 2>&1
if [ $? -eq 0 ]; then
    echo -e "=> Chrooted configuration finished"
else
    echo -e "=> Chrooted configuration failed" >&2
    exit 1
fi

## Setting up user environment
### This part should depend on specific commandline argument
mkdir -p /mnt/home/nick/.local/
cp -r setup/ /mnt/home/nick/.local/.
cp -r /root/.ssh /mnt/home/nick/.

chmod +x /mnt/home/nick/.local/setup/*

arch-chroot /mnt /home/nick/.local/setup/setup_user.sh 2>&1
if [ $? -eq 0 ]; then
    echo -e "=> Setting up user environmet finished"
else
    echo -e "=> Setting up user environmet failed" >&2
    exit 1
fi
##

echo -e "=> Arch Linux installation finished!"
