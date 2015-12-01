#!/bin/bash

# Setup a GDI server, part IV: Import data into database
# Made for Ubuntu 14.04 x64 at DigitalOcean
#
# This script must be run with normal user privileges


# Variables
hostname=localhost
dbname=geodb
datausername=data_user


# Import DM01AVSO24 data

# Download data
mkdir --parents /geodata/cadastre/av_so_lv03/dm01avso24/itf/
chown --recursive $USER:geodata_admin /geodata/cadastre/av_so_lv03/
#chmod --recursive g+w /geodata/cadastre/av_so_lv03/ # is actually not necessary
curl -O --remote-time http://www.sogis1.so.ch/sogis/daten/kva/av/itf_so/254900.zip
unzip -d /geodata/cadastre/av_so_lv03/dm01avso24/itf/ 254900.zip 254900.itf
mv 254900.zip /geodata/cadastre/av_so_lv03/dm01avso24/itf/



# Define DB user and password
dbusr=$datausername
dbpwd=$(awk -F ':' '/'$dbusr'/ {print $5}' .pgpass) # hack: fetch password from .pgpass

# Import data
java -jar ili2pg-2.3.0/ili2pg.jar --import --deleteData --dbhost $hostname --dbdatabase $dbname --dbschema av_dm01avso24_transfer --dbusr $dbusr --dbpwd $dbpwd --log import_av_dm01avso24_transfer.log  /geodata/cadastre/av_so_lv03/dm01avso24/itf/254900.itf # and maybe: --importTid

# TODO: VACUUM and/or at least ANALYZE

