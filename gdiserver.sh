#!/bin/bash

# Setup a GDI server, part II
# Made for Ubuntu 14.04 x64 at DigitalOcean

# This script must be run as user with sudo privileges


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


# Upgrade outdate packages and install various tools
apt-get update
# alternative: apt-get --yes dist-upgrade
apt-get --yes upgrade
apt-get install git zip

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


# Install GDAL
apt-get update
apt-get --yes install gdal-bin python-gdal
# workaround for fixing wrong towgs84 parameters:
gdalversion=`gdalinfo --version | awk -F ' '  '{ print $2 }' | awk -F . '{ print $1 "." $2 }'`
echo "4149,CH1903,6149,CH1903,6149,9122,7004,8901,1,0,6422,1766,1,9603,674.374,15.056,405.346,,,," >> /usr/share/gdal/$gdalversion/gcs.override.csv
# download NTv2 grids from Swisstopo and make available for PROJ.4:
# (the Swisstopo page providing these downloads is http://www.swisstopo.admin.ch/internet/swisstopo/de/home/products/software/products/chenyx06.html, reachable via Products > Geodetic Software > Products and tools > CHENyx06 dataset)
curl -O http://www.swisstopo.admin.ch/internet/swisstopo/en/home/products/software/products/chenyx06.parsys.00011.downloadList.70576.DownloadFile.tmp/chenyx06ntv2.zip
curl -O http://www.swisstopo.admin.ch/internet/swisstopo/en/home/products/software/products/chenyx06.parsys.00011.downloadList.29885.DownloadFile.tmp/chenyx06etrs.gsb
unzip -d /usr/share/proj/ chenyx06ntv2.zip CHENYX06a.gsb
cp chenyx06etrs.gsb /usr/share/proj/
chown $USER: chenyx06ntv2.zip
chown $USER: chenyx06etrs.gsb




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

# Install QGIS (packages)
# For use without ubuntugis-unstable:
# echo "deb     http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# echo "deb-src http://qgis.org/debian-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
# For use with ubuntugis-unstable:
echo "deb     http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
echo "deb-src http://qgis.org/ubuntugis-nightly trusty main" >> /etc/apt/sources.list.d/qgis.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com DD45F6C3
apt-get update
apt-get install --yes qgis python-qgis qgis-plugin-grass
apt-get install apache2 libapache2-mod-fcgid
apt-get install --yes qgis-server
# TODO: Maybe some .../crssync is necessary

# Next do something like ln -s /usr/local/qgis_master/bin/qgis_mapserv.fcgi /usr/lib/cgi-bin/qgis_mapserv.fcgi
# maybe chmod and chown ... /usr/lib/cgi-bin/qgis_mapserv.fcgi
# write config into /etc/apache/mods-available/mod-fcgi.conf


