#!/bin/bash

# Setup a GDI server, part II
# Made for Ubuntu 14.04 x64 at DigitalOcean

# This script must be run as user with sudo privileges


# Create and configure a 4GB swap file according to
# https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile

swapon /swapfile
echo "/swapfile                                 none            swap    sw                0       0" >> /etc/fstab

sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf



# Add repositories and keys
add-apt-repository --yes ppa:ubuntugis/ubuntugis-unstable
add-apt-repository --yes ppa:x2go/stable


# Upgrade outdated packages and install various tools
apt-get update
# alternative, but might need to reboot: apt-get --yes dist-upgrade
apt-get --yes upgrade
apt-get --yes install git zip pwgen
apt-get clean



# Install GDAL
apt-get --yes install gdal-bin python-gdal
apt-get clean
# workaround for fixing wrong towgs84 parameters:
# (maybe check first: gdalsrsinfo -o proj4 EPSG:4149)
gdalversion=`gdalinfo --version | awk -F ' '  '{ print $2 }' | awk -F . '{ print $1 "." $2 }'`
echo "4149,CH1903,6149,CH1903,6149,9122,7004,8901,1,0,6422,1766,1,9603,674.374,15.056,405.346,,,," >> /usr/share/gdal/$gdalversion/gcs.override.csv
# download NTv2 grids from Swisstopo and make available for PROJ.4:
# (the Swisstopo page providing these downloads is http://www.swisstopo.admin.ch/internet/swisstopo/de/home/products/software/products/chenyx06.html, reachable via Products > Geodetic Software > Products and tools > CHENyx06 dataset)
curl -O http://www.swisstopo.admin.ch/internet/swisstopo/en/home/products/software/products/chenyx06.parsys.00011.downloadList.70576.DownloadFile.tmp/chenyx06ntv2.zip
curl -O http://www.swisstopo.admin.ch/internet/swisstopo/en/home/products/software/products/chenyx06.parsys.00011.downloadList.29885.DownloadFile.tmp/chenyx06etrs.gsb
unzip -o -d /usr/share/proj/ chenyx06ntv2.zip CHENYX06a.gsb
cp chenyx06etrs.gsb /usr/share/proj/
chmod 644 /usr/share/proj/CHENYX06a.gsb
chown $SUDO_USER: chenyx06ntv2.zip
chown $SUDO_USER: chenyx06etrs.gsb



# Install and configure PostGIS
apt-get --yes install postgis postgresql-9.3-postgis-2.1
apt-get clean

dbname=geodb
datausername=data_user

# Create .pgpass file (generate passwords)
echo \#hostname:port:database:username:password > .pgpass
echo localhost:*:*:$SUDO_USER:`pwgen --secure 16`- >> .pgpass
echo localhost:*:*:$datausername:`pwgen --secure 16`* >> .pgpass
chmod 0600 .pgpass
chown $SUDO_USER: .pgpass

# Configure listen_addresses
serverip=`ifconfig eth0 | grep "inet " | awk '{gsub("addr:","",$2);  print $2 }'`
echo "# -----------------------------" > /etc/postgresql/9.3/main/postgresql.include.conf
echo "# PostgreSQL customized options" >> /etc/postgresql/9.3/main/postgresql.include.conf
echo "# -----------------------------" >> /etc/postgresql/9.3/main/postgresql.include.conf
echo "listen_addresses = 'localhost, $serverip'" >> /etc/postgresql/9.3/main/postgresql.include.conf
echo "include = 'postgresql.include.conf'     # customized settings" >> /etc/postgresql/9.3/main/postgresql.conf

# Configure pg_hba.conf
currentclientip=`echo $SSH_CLIENT | awk '{print $1}'`
echo "# Custom entries" >> /etc/postgresql/9.3/main/pg_hba.conf
echo "host    $dbname           $SUDO_USER         $currentclientip/32          md5" >> /etc/postgresql/9.3/main/pg_hba.conf
echo "host    $dbname           $datausername      $currentclientip/32          md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# Restart PostgreSQL after these changes
service postgresql restart

# Create login roles
pwd=`grep $SUDO_USER .pgpass | awk -F ':' '{print $5}'` # hack: fetch password from .pgpass -- old solution, remove
pwd=`awk -F ':' '/'$SUDO_USER'/ {print $5}' .pgpass` # hack: fetch password from .pgpass
su postgres -c "psql -c \"CREATE ROLE ${SUDO_USER} LOGIN PASSWORD '${pwd}';\" " # alternative command: su postgres -c "createuser --pwprompt ${SUDO_USER}" # asks for the password
pwd=`grep $datausername .pgpass | awk -F ':' '{print $5}'` # hack: fetch password from .pgpass -- old solution, remove
pwd=`awk -F ':' '/'$datausername'/ {print $5}' .pgpass` # hack: fetch password from .pgpass
su postgres -c "psql -c 'CREATE ROLE ${datausername} LOGIN PASSWORD '${pwd}';'"
unset pwd
# Create "function roles"
su postgres -c "psql -c 'CREATE ROLE super SUPERUSER NOINHERIT;'"
su postgres -c "psql -c 'CREATE ROLE admin CREATEDB CREATEROLE NOINHERIT;'"
# Create "group roles"
su postgres -c "psql -c 'CREATE ROLE administrators NOINHERIT;'" # the basic concept is that all login roles should INHERIT group role privileges; this is, however, an "intermediate" role to prevent INHERIT of the admin role privileges to the user
su postgres -c "psql -c 'GRANT admin TO administrators;'"
# Assign roles
su postgres -c "psql -c 'GRANT administrators TO ${SUDO_USER} WITH ADMIN OPTION;'" # for che chief admins: WITH ADMIN OPTION; for other admins: without ADMIN OPTION
su postgres -c "psql -c 'GRANT super TO ${SUDO_USER};'"

# Create DB
su postgres -c "createdb -O admin ${dbname}"
# Install PostGIS in this DB
su postgres -c "psql -d ${dbname} -c 'CREATE EXTENSION postgis';"
# TODO: Maybe some GRANT necessary for geometry_columns etc.
# TODO: Need to fix wrong towgs84 parameters for EPSG:21781 here too, and for EPSG:4149, maybe even more

# Fine tune DB privileges
su postgres -c "psql -d ${dbname} -c 'REVOKE CREATE ON SCHEMA public FROM PUBLIC;'" # otherwise every user could create objects in the public schema
# TODO: Not working: su postgres -c "psql -c 'GRANT CREATE ON SCHEMA public TO admin;'"
su postgres -c "psql -c 'GRANT CREATE ON DATABASE ${dbname} TO admin;'" # allow creating new schemas



# Setup the root directory of the file geodata repository
mkdir /geodata/
chown root:geodata_admin /geodata/
chmod g+w /geodata/



# Install Java Runtime Environment and ili2pg-2.3.0
apt-get --yes install default-jre-headless
apt-get clean
curl -O http://www.eisenhutinformatik.ch/interlis/ili2pg/ili2pg-2.3.0.zip
unzip ili2pg-2.3.0.zip
chown $SUDO_USER: ili2pg-2.3.0.zip
chown --recursive $SUDO_USER: ili2pg-2.3.0/



# Install X2Go server
apt-get --yes install x2goserver x2goserver-xsession
apt-get clean



# Install QGIS (packages)
# For use without ubuntugis-unstable:
# echo "deb http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# echo "deb-src http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# For use with ubuntugis-unstable:
echo "deb http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
echo "deb-src http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 3FF5FFCAD71472C4
apt-get update
apt-get install --yes qgis python-qgis
# qgis.org actually proposes: apt-get install --yes qgis python-qgis qgis-plugin-grass
apt-get clean
apt-get install --yes qgis-server
apt-get install --yes apache2 libapache2-mod-fcgid
apt-get clean
# TODO: Maybe some .../crssync is necessary

# Next do something like ln -s /usr/local/qgis_master/bin/qgis_mapserv.fcgi /usr/lib/cgi-bin/qgis_mapserv.fcgi
# maybe chmod and chown ... /usr/lib/cgi-bin/qgis_mapserv.fcgi
# write config into /etc/apache/mods-available/mod-fcgi.conf



# Install QGIS and QGIS Server (compile and install)
# TODO: Check how to install QGIS Server (Master) only
# apt-get update
# apt-get --yes build-dep qgis
# apt-get --yes install libqscintilla2-dev

# mkdir ~/sources
# git clone https://github.com/qgis/QGIS.git ~/sources/qgis_master
# mkdir ~/sources/qgis_master/build
# cd ~/sources/qgis_master/build
# cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/qgis_master -DCMAKE_INSTALL_RPATH=/usr/local/qgis_master/lib -DENABLE_TESTS=OFF -DWITH_SERVER=ON
# make -j 4
# make install
# cd ~
# /usr/local/qgis_master/lib/qgis/crssync



# Show message
echo Part II is finished.