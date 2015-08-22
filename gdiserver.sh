#!/bin/bash

# Setup a GDI server, part II
# Made for Ubuntu 14.04 x64 at DigitalOcean

# This script must be run as user with sudo privileges


# Generate locale for Switzerland
locale-gen de_CH.utf8


# Create and configure a 4GB swap file
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile

swapon /swapfile
echo "/swapfile                                 none            swap    sw                0       0" >> /etc/fstab

sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf


# Add ubuntugis-unstable apt repository and keys
add-apt-repository --yes ppa:ubuntugis/ubuntugis-unstable


apt-get update
# better use apt-get --yes dist-upgrade?
apt-get --yes upgrade

# Install and configure PostGIS
apt-get update
apt-get --yes install postgis postgresql-9.3-postgis-2.1

su postgres -c "createuser -s $USER"
su postgres -c "createdb -O $USER geodb"
# TODO: just to be sure we're not user postgres anymore, remove soon:
touch test.txt


# Install Java Runtime Environment
# Note: install default-jre instead of default-jre-headless if necessary
apt-get update
apt-get --yes install default-jre-headless


# Compile and install QGIS Master including QGIS Server
# TODO: Check how to install QGIS Server (Master) only
apt-get update
apt-get --yes build-dep qgis
apt-get --yes install libqscintilla2-dev git
apt-get --yes install gdal-bin
# TODO: Download NTv2-Grids and copy to /usr/share/proj/
gdalversion=`gdalinfo --version | awk -F ' '  '{ print $2 }' | awk -F . '{ print $1 "." $2 }'`
echo "4149,CH1903,6149,CH1903,6149,9122,7004,8901,1,0,6422,1766,1,9603,674.374,15.056,405.346,,,," >> /usr/share/gdal/$gdalversion/gcs.override.csv

mkdir ~/sources
git clone https://github.com/qgis/QGIS.git ~/sources/qgis_master
mkdir ~/sources/qgis_master/build
# TODO: following command is not working:
cd ~/sources/qgis_master/build
# TODO: not thoroughly tested yet
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/qgis_master -DCMAKE_INSTALL_RPATH=/usr/local/qgis_master/lib -DENABLE_TESTS=OFF -DWITH_SERVER=ON
make
make install
# TODO: Maybe some .../crssync is necessary
cd ~

# Alternatively, download and install QGIS packages
# For use without ubuntugis-unstable:
# echo "deb     http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# echo "deb-src http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# For use with ubuntugis-unstable:
# echo "deb     http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# echo "deb-src http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# apt-key adv --recv-keys --keyserver keyserver.ubuntu.com DD45F6C3
# apt-get update
# apt-get install --yes qgis python-qgis qgis-plugin-grass
# apt-get install apache2 libapache2-mod-fcgid
# qgis-server or qgis-mapserver?
# apt-get install --yes qgis-server
# TODO: Maybe some .../crssync is necessary

# Next do something like ln -s /usr/local/qgis_master/bin/qgis_mapserv.fcgi /usr/lib/cgi-bin/qgis_mapserv.fcgi
# maybe chmod and chown ... /usr/lib/cgi-bin/qgis_mapserv.fcgi
# write config into /etc/apache/mods-available/mod-fcgi.conf


