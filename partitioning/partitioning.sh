#!/bin/sh

SUBHORIZONTALE="==========================="

PART_INSTR="partitioning/partition-table.conf"

check_returncode() {
    local RETURN=${1} ERRORTEXT=${2}
    if [ $RETURN -eq 0 ]; then
        echo "OK"
        return 0
    else
        echo "${ERRORTEXT}" >&2
        exit $RETURN
    fi
}

echo -e "\n$SUBHORIZONTALE"
echo -e "       Partitioning"
echo -e "$SUBHORIZONTALE\n"

if [ -f "$PART_INSTR" ]; then

    echo -ne "Applying partition instructions...\t\t"
    # sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
    ERROR=$(cat $PART_INSTR | sfdisk /dev/sda 2>&1 1>/dev/null)
    check_returncode $? $ERROR

    echo -ne "Verifying Partition table...\t\t\t"
    # sfdisk -V: verifies the partition table of /dev/sda
    ERROR=$(sfdisk -V /dev/sda 2>&1 1>/dev/null)
    check_returncode $? $ERROR

    ## Subsection: Format the partitions
    echo -ne "Formatting root partition...\t\t\t"
    ERROR=$(mkfs.ext4 -q /dev/sda1 2>&1 1>/dev/null)
    check_returncode $? $ERROR

    echo -ne "Initializing swap partition...\t\t\t"
    ERROR=$(mkswap /dev/sda2 2>&1 1>/dev/null)
    check_returncode $? $ERROR

    echo -ne "Enabling swap partition...\t\t\t"
    ERROR=$(swapon /dev/sda2 2>&1 1>/dev/null)
    check_returncode $? $ERROR

else
    RETURN=$?
    echo "${PART_INSTR} not found" >&2
    exit $RETURN
fi

exit 0

