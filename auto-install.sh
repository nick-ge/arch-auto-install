#!/bin/sh

# This is a script which should automate the Arch-Linux installation process for my
# specific device.
# Bases on https://wiki.archlinux.org/index.php/Installation_guide

HORIZONTALE="==================================================="
SUBHORIZONTALE="==========================="

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
        echo "ERROR"
        echo "$ERRORTEXT" >&2
        echo "=> Installation process aborted"
        exit $RETURN
    fi
}

echo -e "\n$HORIZONTALE"
echo -e "\t   Arch Linux Installation Script"
echo -e "$HORIZONTALE\n"

# Section: Pre-Installation

echo -ne "Synchronizing system clock...\t\t\t"
ERROR=$(timedatectl set-ntp true 2>&1 1>/dev/null)
check_returncode $? $ERROR

./partitioning/partitioning.sh
if [ $? -eq 0 ]; then
    echo -e "=> Partitioning successfully finished\n"
else
    echo "=> Partitioning failed" >&2
    exit 1
fi

## Subsection: Mounting the file system

echo -ne "Mounting file system to /mnt...\t\t\t"
ERROR=$(mount /dev/sda1 /mnt 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Installation

echo -ne "Downloading current mirrorlist...\t\t"
ERROR=$(curl --silent "https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4" | sed 's/#Server/Server/' > /etc/pacman.d/mirrorlist)
check_returncode $? $ERROR

echo -ne "Installing essential packages...\t\t"
ERROR=$(pacstrap /mnt $(cat packagelist) 2>&1 1>/dev/null)
#ERROR=$(pacstrap /mnt base base linux linux-firmware grub 2>&1 1>/dev/null)
check_returncode $? $ERROR

# Section: Configure the system

echo -ne "Generating an fstab file...\t\t\t"
ERROR=$(genfstab -U /mnt 2>&1 1>>/mnt/etc/fstab)
check_returncode $? $ERROR

# Subsection: Chroot

mkdir /mnt/root/.ssh
cp /root/.ssh/id_rsa /mnt/root/.ssh/.

cp -r chrooted/ /mnt/root/.
chmod +x /mnt/root/chrooted/chrooted.sh
chmod +x /mnt/root/chrooted/creater_user.sh

arch-chroot /mnt /root/chrooted.sh 2>&1

if [ $? -eq 0 ]; then
    echo -e "=> Chrooted configuration successfully finished\n"
else
    echo -e "=> Chrooted configuration failed" >&2
    exit 1
fi

echo -e "=> Arch base installation finished!"
