#!/bin/bash

# fsubcp - submits a farm job for 12c migration
#
# Author: Manish Chacko
# Created on: 06-Dec-2018
# Last updated: 06-Dec-2018
# Version 0.1
# 
# Usage:
# fsubcp.sh labelID

if [ "$1" = "" ]; then
	echo "Please provide label id of farm job. Unable to continue"
	exit
fi

jdev_location="/ade_autofs/ud62_fa/FUSIONAPPS_PT.V2MIB_LINUX.X64.rdd/LATEST/fatools/bin/jdev"

fa_label=`farm showjobs -details -label $1 | grep "base label" | awk '{print $4}'`
echo "Job label: $fa_label"

log_location=`farm showjobs -details -label $1 | grep "Results location" | awk '{print $4}'`
log_location="$log_location/build"
echo "Job results location: $log_location"

log_copy_location="/net/slc10tzw/scratch/sailv/migrationlogs/hed/"
#log_copy_location="/net/den01ghp.us.oracle.com/scratch/migrationlogs/hed"

echo "Creating target directory: $log_copy_location/$fa_label"
mkdir $log_copy_location/$fa_label

echo -n "Copying compilation files... "
cp $log_location/compile.log $log_copy_location/$fa_label/ 
cp $log_location/fusionapps/build-report.html $log_copy_location/$fa_label/ 
cp $log_location/work/fusionapps/ojdeploy.statusreport.xml $log_copy_location/$fa_label/ 
echo  "done."

$jdev_location ojdeployRpt $log_copy_location/$fa_label/ojdeploy.statusreport.xml > $log_copy_location/$fa_label/hed_${fa_label}.log
$jdev_location createBldRpt ${fa_label} $log_copy_location/$fa_label/hed_${fa_label}.log > $log_copy_location/$fa_label/hed_${fa_label}.rpt

#email me the report
cat $log_copy_location/$fa_label/hed_${fa_label}.rpt | mutt manish.chacko@oracle.com -a $log_copy_location/$fa_label/hed_${fa_label}.log -a $log_copy_location/$fa_label/hed_${fa_label}.rpt -a $log_copy_location/$fa_label/build-report.html -s "12c FARM migration report for label $fa_label"



