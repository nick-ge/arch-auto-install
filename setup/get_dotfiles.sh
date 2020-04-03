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
ERROR=$(ssh-keyscan -t rsa github.com 2>&1 1> ~/.ssh/known_hosts)
check_returncode $? "$ERROR"

echo -e "\nCloning repository 'nick-ge/dot-files'..."
ERROR=$(git clone -q git@github.com:nick-ge/dot-files.git ~/dot-files 2>&1)
rt=$?

if [ $rt -eq 0 ] && [ -d "/root/dot-files" ]; then

    echo -ne "Copying git directory...\t\t\t"
    ERROR=$(cp -r /root/dot-files/.git ~/.dotfiles.git 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    # Active globbing on hidden-/dotfiles
    shopt -s dotglob

    echo -ne "Moving dotfiles to home...\t\t\t"
    ERROR=$(mv ~/dot-files/* ~/. 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    echo -ne "Removing repository from root...\t\t"
    ERROR=$(rm -r ~/dot-files 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    echo -ne "Creating 'exclude' file...\t\t\t"
    ERROR=$(echo "*" 2>&1 1>>~/.dotfiles.git/info/exclude)
    check_returncode $? "$ERROR"

    echo -ne "Changing owner to nick...\t\t\t"
    ERROR=$(chown -R nick:users ~/* 2>&1 1>/dev/null)
    check_returncode $? "$ERROR"

    # Deactive globbing
    shopt -u dotglob
else
    echo -e "=> Something went wrong while cloning!"
    echo "$ERROR" >&2
    exit $rt
fi

exit 0
