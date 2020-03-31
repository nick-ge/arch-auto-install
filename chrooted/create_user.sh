#!/bin/sh

SUBHORIZONTALE="==========================="

GROUPS="wheel,wireshark,tor,users"
SHELL="/bin/zsh"

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
echo -e " Creating User"
echo -e "$SUBHORIZONTALE\n"

read -p "Enter username [default: nick]: " username
if [ "$username" = "" ]; then
    username="nick"
fi

echo -ne "Adding user ${username}...\t\t\t"
ERROR=$(useradd -m -G $GROUPS -s $SHELL $username 2>&1 1>/dev/null)
check_returncode $? $ERROR

echo "Password needed for ${username}"
passwd nick
if [ $? -ne 0 ]; then
    echo "Setting password for ${username} failed" >&2
    exit 1
fi

exit 0
