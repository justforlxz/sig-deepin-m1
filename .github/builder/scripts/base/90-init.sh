#!/bin/bash

# echo "root:deepin" | chpasswd

perl -p -i -e 's/root:x:/root::/' /etc/passwd

systemctl enable debug-shell

update-initramfs -u -c -k all
