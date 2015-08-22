#!/bin/bash

# Setup a GDI server, part I
# Made for Ubuntu 14.04 x64 at DigitalOcean 

# This script must be run as root

# Arguments: 
# $1 (mandatory): username of the additional user to create
# $2 (mandatory): git branch to get part II script from


locale-gen de_CH.utf8
# Maybe set time zone, e.g.
# echo "Europe/Zurich" | tee /etc/timezone
# dpkg-reconfigure --frontend noninteractive tzdata


adduser --gecos "" $1
adduser $1 sudo

cp -r /root/.ssh/ /home/$1/
chown -R $1: /home/$1/.ssh/

curl -o /home/$1/gdiserver.sh https://raw.githubusercontent.com/schmandr/gdiserver/$2/gdiserver.sh
chown $1: /home/$1/gdiserver.sh
chmod +x /home/$1/gdiserver.sh