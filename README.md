# gdiserver
Setup your own geodata server.

Scripts for Ubuntu Server 14.04 x64.


##How to use these scripts:
* Log in to your server with the root account, using ssh
* run `curl -O https://raw.githubusercontent.com/schmandr/gdiserver/master/gdiserver_root.sh`
* run `chmod +x gdiserver_root.sh`
* run `./gdiserver_root.sh USERNAME master` (USERNAME is the name of a new administrative user that will be created; you will be asked to set a password for this user - choose it carefully)
* Log out
* Log in to your server with the just created USERNAME account, using ssh
* run `sudo ./gdiserver.sh`
