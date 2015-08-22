#!/bin/bash

# Setup a GDI server, part I
# Made for Ubuntu 14.04 x64 at DigitalOcean 

# This script must be run as root

# Arguments: $1: username of the additional user to create

adduser --gecos "" $1
adduser $1 sudo

cp -r /root/.ssh/ /home/$1/
chown -R $1: /home/$1/.ssh/

curl curl -o /home/$1/gdiserver.sh https://raw.githubusercontent.com/schmandr/gdiserver/master/gdiserver.sh
chown $1: /home/$1/gdiserver.sh
