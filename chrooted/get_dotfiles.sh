#!/bin/sh

SUBHORIZONTALE="==========================="

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
echo -e "\t Dotfiles"
echo -e "$SUBHORIZONTALE\n"


echo -ne "Retrieving public key from GitHub...\t\t"
ssh-keyscan -t rsa github.com 1> ~/.ssh/known_hosts 2>/dev/null
rt=$?

if [ $rt -eq 0 ]; then
    echo "OK"
else
    echo -e "ERROR\n"
    exit $rt
fi

echo -e "\nCloning repository 'nick-ge/dot-files'..."
ERROR=$(git clone -q git@github.com:nick-ge/dot-files.git /root/. 2>&1)
rt=$?

if [ $rt -eq 0 ] && [ -d "/root/dot-files" ]; then

    echo -ne "Copying git directory...\t\t\t"
    ERROR=$(cp -r /root/dot-files/.git /home/nick/.dotfiles.git 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    # Active globbing on hidden-/dotfiles
    shopt -s dotglob

    echo -ne "Moving dotfiles to home...\t\t\t"
    ERROR=$(mv /root/dot-files/* /home/nick/. 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    # Deactive globbing
    shopt -u dotglob

    echo -ne "Removing repository from root...\t\t"
    ERROR=$(rm -r /root/dot-files 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    echo -ne "Creating 'exclude' file...\t\t"
    ERROR=$(echo "*" >> /home/nick/.dotfiles.git/info/exclude 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

else
    echo -e "=> Cloning failed!"
    echo "$ERROR" >&2
    exit $rt
fi

exit 0
