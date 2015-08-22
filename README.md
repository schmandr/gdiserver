# gdiserver
Setup your own geodata server in minutes.

Scripts for Ubuntu Server 14.04 x64.


How to use these scripts:
* Log in to your server with the root account, using ssh
* run curl -O https://raw.githubusercontent.com/schmandr/gdiserver/master/gdiserver_root.sh
* run chmod +x gdiserver_root.sh
* run ./gdiserver_root.sh <SELECT_A_USERNAME_HERE> master
* Log out
* Log in to your server with the <SELECT_A_USERNAME_HERE> account, using ssh
* run sudo ./gdiserver.sh