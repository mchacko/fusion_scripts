#!/bin/bash

# jaznBuilder - Builds FSCM system jazn, and runs 3 way merge
# 
# 
#
# Author: Manish Chacko
# Created on: 15-May-2018
# Last updated: 15-May-2018
# Version 0.1
# 
# Usage:
# jaznBuilder.sh 
#

script_start_time=$(date +%s)
user=`whoami`

#check if the command is run from a view
view="$(ade pwv)"
if [ "$view" = "ade ERROR: Not in a view." ]; then
	echo "Please run this command in a view."
	exit
fi

#run FSCM jazn build

echo "Starting FSCM system jazn build"
ant -f $AVR/fabuildtools/ant/drivers/build-ldap-migration.xml buildFscm | tee $AVR/fusionapps/buildfscmJazn.log

v2mb_latest_label="$(ade showlabels -series FUSIONAPPS_PT.V2MIB_LINUX.X64  -latest | grep FUSIONAPPS_PT)"
echo "V2MIB latest label is $v2mb_latest_label"
echo ""

v2mb_latest_label_location="$(ade desc -l  $v2mb_latest_label -labelserver)"
echo "V2MIB label server location is $v2mb_latest_label_location"
echo ""

echo "processing jps-config.xml..."
cp -f ~/scripts/jps-config.xml $AVR/fusionapps/
sed  -i "s#CHANGEME#${v2mb_latest_label_location}#g" $AVR/fusionapps/jps-config.xml

echo "Creating jaznDelta directory..."
mkdir $AVR/fusionapps/jaznDelta


#set env varibales for wls script
ADEAUTOFSCHANGEME="${v2mb_latest_label_location}"
AVRSYSTEMJAZNCHAGEME="$AVR/fusionapps/fscm/deploy/system-jazn-data.xml"
JPSCNFIGCHANGEME="$AVR/fusionapps/jps-config.xml"
AVRJAZNDELTACHANGEME="$AVR/fusionapps/jaznDelta"

export ADEAUTOFSCHANGEME
export AVRSYSTEMJAZNCHAGEME
export JPSCNFIGCHANGEME
export AVRJAZNDELTACHANGEME

echo "Invoking 3 way merge..."

$MW_HOME/oracle_common/common/bin/wlst.sh ~/scripts/merge_3_way.py

