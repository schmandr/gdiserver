#!/bin/bash

# Setup a GDI server, part III: Import database schemas (models)
# Made for Ubuntu 14.04 x64 at DigitalOcean
#
# This script must be run with normal user privileges


# Variables
hostname=localhost
dbname=geodb
dbusr=$USER
datausername=data_user


# Create INTERLIS model repository directory
mkdir --parents /geodata/interlismodels/
chown --recursive $USER:geodata_admin /geodata/interlismodels/
#chmod --recursive g+w /geodata/interlismodels/ # is actually not necessary



# Create DB schema av_dm01avso24_transfer

# Download INTERLIS model
curl -O --remote-time http://www.sogis1.so.ch/sogis/daten/kva/av/itf_so/254900.zip
unzip -d /geodata/interlismodels/ 254900.zip dm01avso24.ili
# TODO: chown, chmod
rm 254900.zip

# Create empty DB schema
dbpwd=$(awk -F ':' '/'$dbusr'/ {print $5}' .pgpass) # hack: fetch password from .pgpass
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; CREATE SCHEMA av_dm01avso24_transfer; GRANT USAGE ON SCHEMA av_dm01avso24_transfer TO $datausername, $dbusr; GRANT CREATE ON SCHEMA av_dm01avso24_transfer TO $dbusr;" # GRANT CREATE ... TO $dbusr is a workaround, as with ili2pg no SET ROLE admin is possible
# Import INTERLIS model
java -jar ili2pg-2.3.0/ili2pg.jar --schemaimport --dbhost $hostname --dbdatabase $dbname --dbschema av_dm01avso24_transfer --dbusr $dbusr --dbpwd $dbpwd --createscript create_av_dm01avso24_transfer.sql --createGeomIdx --createSingleEnumTab --t_id_Name ogc_fid --nameByTopic --importTid --log create_av_dm01avso24_transfer.log --modeldir /geodata/interlismodels/ --models DM01AVSO24 # and maybe: --createFk --createFkIdx --createBasketCol

# Grant privileges needed to $datausername (the DB user that will import data later on)
awk -v rolename=$datausername -F ' ' '/CREATE TABLE/ { printf("GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE %s TO %s;\n", $3, rolename) }' create_av_dm01avso24_transfer.sql > grant_av_dm01avso24_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -f grant_av_dm01avso24_transfer.sql # different solution would be: GRANT ... ON ALL TABLES IN SCHEMA av_dm01avso24_transfer TO ...
# Set table owner to admin and revoke CREATE from $dbuser (the following lines are part of the SET ROLE admin workaround)
awk -F ' ' '/CREATE TABLE/ { printf("ALTER TABLE %s OWNER TO admin;\n", $3) }' create_av_dm01avso24_transfer.sql > alter_table_owner_av_dm01avso24_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -f alter_table_owner_av_dm01avso24_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; REVOKE CREATE ON SCHEMA av_dm01avso24_transfer FROM $dbusr; REVOKE USAGE ON SCHEMA av_dm01avso24_transfer FROM $dbusr;"



# Create DB schema av_mopublic13_transfer

# Download INTERLIS model
curl -O --remote-time http://www.cadastre.ch/internet/kataster/de/tools/reference.parsys.99025.downloadList.91095.DownloadFile.tmp/mopublicili1env1.3.zip
unzip -d /geodata/interlismodels/ mopublicili1env1.3.zip MOpublic03_ili1_v1.3.ili LookUp_ili1_v1.3.ili
# TODO: chown, chmod
# rm mopublicili1env1.3.zip

# Create empty DB schema
dbpwd=$(awk -F ':' '/'$dbusr'/ {print $5}' .pgpass) # hack: fetch password from .pgpass
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; CREATE SCHEMA av_mopublic13_transfer; GRANT USAGE ON SCHEMA av_mopublic13_transfer TO $datausername, $dbusr; GRANT CREATE ON SCHEMA av_mopublic13_transfer TO $dbusr;" # GRANT CREATE ... TO $dbusr is a workaround, as with ili2pg no SET ROLE admin is possible
# Import INTERLIS models
java -jar ili2pg-2.3.0/ili2pg.jar --schemaimport --dbhost $hostname --dbdatabase $dbname --dbschema av_mopublic13_transfer --dbusr $dbusr --dbpwd $dbpwd --createscript create_av_mopublic13_transfer.sql --createGeomIdx --createEnumColAsItfCode --createSingleEnumTab --t_id_Name ogc_fid --nameByTopic --importTid --log create_av_mopublic13_transfer.log --modeldir /geodata/interlismodels/ --models 'MOpublic03_ili1_v13;LookUp_ili1_v13' # --createEnumColAsItfCode is rather not necessary

# Grant privileges needed to $datausername (the DB user that will import data later on)
awk -v rolename=$datausername -F ' ' '/CREATE TABLE/ { printf("GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE %s TO %s;\n", $3, rolename) }' create_av_mopublic13_transfer.sql > grant_av_mopublic13_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -f grant_av_mopublic13_transfer.sql
# Set table owner to admin and revoke CREATE from $dbuser (the following lines are part of the SET ROLE admin workaround)
awk -F ' ' '/CREATE TABLE/ { printf("ALTER TABLE %s OWNER TO admin;\n", $3) }' create_av_mopublic13_transfer.sql > alter_table_owner_av_mopublic13_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -f alter_table_owner_av_mopublic13_transfer.sql
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; REVOKE CREATE ON SCHEMA av_mopublic13_transfer FROM $dbusr; REVOKE USAGE ON SCHEMA av_mopublic13_transfer FROM $dbusr;"



# Create DB schema work_full01
exit 0 # TODO: disabled for now
# Download INTERLIS model
curl -O --remote-time https://raw.githubusercontent.com/schmandr/gdiserver/work/dmwork_full01.ili
mv dmwork_full01.ili /geodata/interlismodels/
# TODO: chown, chmod

# Create empty DB schema
dbpwd=$(awk -F ':' '/'$dbusr'/ {print $5}' .pgpass) # hack: fetch password from .pgpass
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; CREATE SCHEMA av_work_full01; GRANT USAGE ON SCHEMA av_work_full01 TO $datausername, $dbusr; GRANT CREATE ON SCHEMA av_work_full01 TO $dbusr;" # GRANT CREATE ... TO $dbusr is a workaround, as with ili2pg no SET ROLE admin is possible
java -jar ili2pg-2.3.0/ili2pg.jar --schemaimport --dbhost $hostname --dbdatabase $dbname --dbschema av_work_full01 --dbusr $dbusr --dbpwd $dbpwd --createscript create_av_work_full01.sql --createGeomIdx --createSingleEnumTab --t_id_Name ogc_fid --nameByTopic --importTid --log create_av_work_full01.log --modeldir /geodata/interlismodels/ --models dmwork_full01.ili

# Grant privileges needed to $datausername (the DB user that will import data later on)
awk -v rolename=$datausername -F ' ' '/CREATE TABLE/ { printf("GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE %s TO %s;\n", $3, rolename) }' create_av_work_full01.sql > grant_av_work_full01.sql
psql -h $hostname -d $dbname -U $dbusr -f grant_av_work_full01.sql
# Set table owner to admin and revoke CREATE from $dbuser (the following lines are part of the SET ROLE admin workaround)
awk -F ' ' '/CREATE TABLE/ { printf("ALTER TABLE %s OWNER TO admin;\n", $3) }' create_av_work_full01.sql > alter_table_owner_av_work_full01.sql
psql -h $hostname -d $dbname -U $dbusr -f alter_table_owner_av_work_full01.sql
psql -h $hostname -d $dbname -U $dbusr -c "SET ROLE admin; REVOKE CREATE ON SCHEMA av_av FROM $dbusr; REVOKE USAGE ON SCHEMA av_work_full01 FROM $dbusr;"
