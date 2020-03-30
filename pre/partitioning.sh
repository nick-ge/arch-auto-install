#!/bin/sh

HORIZONTALE="========================================================================"
SUBHORIZONTALE="===================================="

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

echo -e "\n$SUBHORIZONTALE"
echo -e "\tPartitioning"
echo -e "$SUBHORIZONTALE\n"

echo -ne "Reading partition table...\t\t\t"
PARTITIONTABLE=$(cat partition-table.conf 2>&1)
check_returncode $? $PARTITIONTABLE

echo -ne "Applying partition instructions...\t\t\t"
# sfdisk is a "scriptable" version of fdisk, it receives the "user input" from stdin.
sfdisk /dev/sda 1>/dev/null 2>&1 <<- EOF
    $PARTITIONTABLE
EOF
check_returncode $? "Partitioning with sfdisk failed"

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

exit 0
