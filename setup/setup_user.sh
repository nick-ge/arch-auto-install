#!/bin/sh

chown -R nick:users /home/nick/.local/
chown -R nick:users /home/nick/.ssh/

su -P -c /home/nick/.local/setup/get_dotfiles.sh nick
if [ $? -eq 0 ]; then
    echo "=> Configuring dotfiles finished"
else
    echo "=> Configuring dotfiles failed" >&2
    exit 1
fi

su -P -c /home/nick/.local/setup/aur_packages.sh nick
if [ $? -eq 0 ]; then
    echo "=> Installing AUR Packages finished"
else
    echo "=> Installing AUR Packages failed" >&2
    exit 1
fi
