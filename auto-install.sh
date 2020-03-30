#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide

HORIZONTALE="========================================================================"
SUBHORIZONTALE="===================================="

# Common variable for storing return texts of certain commands
ERROR=""

# Util function which gets invoked after every command.
# It checks the given return code and prints the error message and the
# respective return code in case of an error.
check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo -e "ERROR\n${ERRORTEXT}"
        echo "=> Installation process aborted"
        exit $RETURN
    fi
}

echo -e "\n$HORIZONTALE"
echo -e "\t\t\tArch Linux Installation Script"
echo -e "$HORIZONTALE\n"

# Section: Pre-Installation

echo -ne "Synchronizing system clock...\t\t\t"
ERROR=$(timedatectl set-ntp true 2>&1 1>/dev/null)
check_returncode $? $ERROR

./pre/partitioning.sh

## Subsection: Mounting the file system
echo -ne "Mounting file system to /mnt...\t\t\t"
ERROR=$(mount /dev/sda1 /mnt 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Installation

## Subsection: Select the mirror
echo -ne "Downloading current mirrorlist...\t\t"
ERROR=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? $ERROR

## Subsection: Install essential packages
echo -ne "Installing essential packages...\t\t"
ERROR=$(pacstrap /mnt $(cat packagelist) 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Configure the system

## Subsection: fstab
echo -ne "Generating an fstab file...\t\t\t"
ERROR=$(genfstab -U /mnt 2>&1 1>>/mnt/etc/fstab)
check_returncode $? $ERROR

## Subsection: Chroot

cp chrooted.sh /mnt/root/.
chmod +x /mnt/root/chrooted.sh
echo "Chrooting into new system..."
arch-chroot /mnt /root/chrooted.sh

if [ $? -eq 0 ]; then
    echo "=> Arch base installation successfully finished"
else
    echo "=> Arch base installation failed"
fi
