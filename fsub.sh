#!/bin/bash

# fsub - submits a farm job for 12c migration
# Emails the build report and test report to the machine owner on completion 
# If the build was successful the build report and log will be uploaded to bugDB: set option no_upload to cancel this action
#
# Author: Manish Chacko
# Created on: 06-Dec-2018
# Last updated: 06-Dec-2018
# Version 0.1
# 
# Usage:
# fsub.sh 
specific_label=""

echo ""
echo "***************************************************************************"
echo "******************** Submitting Farm Job **********************************"
echo ""
echo ""


if [ "$1" = "" ]; then
	echo "Please provide a series name - mib, gold or dev. Unable to continue"
	exit
fi

if [ "$1" = "mib" ]; then
	series="FUSIONAPPS_PT.V2MIB_LINUX.X64"
elif [ "$1" = "gold" ]; then
	series="FUSIONAPPS_PT.V2MIBFPHGOLD_LINUX.X64"
elif [ "$1" = "dev" ]; then
	series="FUSIONAPPS_PT.V2MIBFPHDEV_LINUX.X64"
elif [ "${1:0:11}" =  "FUSIONAPPS_" ] ; then
	latest_label="$1"
fi

if [ "$latest_label" = "" ]; then
	latest_label=`ade showlabels -latest -series $series | grep "FUSION"`
fi

echo "Latest label = $latest_label"

series_12c1="FUSIONAPPS_PT.V2MIBFMW12C8_LINUX.X64"
latest_label_12c1=`ade showlabels -latest -series $series_12c1 | grep "FUSION"`
echo "Latest 12C1 label = $latest_label_12c1"

fmw_tools_label=`ade showdepprods -inlabel $latest_label_12c1 | grep "FMWTOOLS_" | awk '{print $3}'`
echo "FMWTOOLS label = $fmw_tools_label"

fmwc_label=`ade showdepprods -inlabel $latest_label_12c1 | grep "FMWC_" | awk '{print $3}'`
echo "FMWC label = $fmwc_label"


farm submit -build -label $latest_label -jobzone ucf atk_all_lrg -user machack -oel60_x64 -publish_label $fmw_tools_label -deplabel $fmw_tools_label -config PREFLIGHT_FMWTOOLS_LABEL=$fmw_tools_label -config FMWC_PREFLIGHT_LABEL=$fmwc_label -config PREFLIGHT_FMWC_LABEL=$fmwc_label -config USE_BUILD_PREFLIGHT=true -config PREFLIGHT_TYPE=12C -config FA_VIRTUAL_ENV=true -config RUN_MIGRATION=true -config PROCESS=migrate_compile -config FAMILY_TO_BUILD=hed -config MULTI_THREAD_ENABLED=true



echo ""
echo "***************************************************************************"
