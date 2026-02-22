#!/bin/bash

# run as root
if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
fi

sudo efibootmgr --bootnext 0001
sudo reboot 0
