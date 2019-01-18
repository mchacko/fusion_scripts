#!/bin/bash

# projBuilder - Builds all projects in transaction without the need to launch jdev
#
# Author: Manish Chacko
# Created on: 30-Aug-2017
# Last updated: 30-Aug-2017
# Version 0.1
# 
# Usage:
# transJarBuilder.sh 
#
# {project name} Name of the project in jdeveloper ex: HedHerCurriculumRegistryModel
#


echo ""
echo "***************************************************************************"
echo "*********************** transaction jar generator  **********************************"
echo ""
echo ""

#check if the command is run from a view
view="$(ade pwv)"
if [ "$view" = "ade ERROR: Not in a view." ]; then
	echo "Please run this command inside a view."
	exit
fi

ojdeploy_tool="$AVR/fmwtools/BUILD_HOME/jdeveloper/jdev/bin/ojdeploy"
her_workspace="$AVR/fusionapps/hed/components/recordsManagement/RecordsManagement.jws"
hey_workspace="$AVR/fusionapps/hed/components/campusCommunity/CampusCommunity.jws"
hes_workspace="$AVR/fusionapps/hed/components/financialsManagement/FinancialsManagement.jws"
fscm_workspace="$AVR/fusionapps/fscm/components/fscmAnalytics/FscmAnalytics.jws"
workspace=""
#var="$1"
log_location=""

ade describetrans | awk -F'[/=]' '{print $2 "/" $3 "/" $4 "/" $5 "/" $6 "/" $7 "/" $8 "/" }' | sort | uniq | grep "^h\|f" > ./projectPaths.txt

while IFS='' read -r line || [[ -n "$line" ]]; do
	jpr_name=""
	jpr_name=`find "$line" -name *.jpr -printf "%f\n"`
	project_name=`echo $jpr_name | cut -d'.' -f 1`
	profile_name="*${project_name}*"
	
	echo "Found project -  $project_name"
	
	workspace=""
	if [ "${project_name:0:6}" =  "HedHer" ] ; then 
	workspace="$her_workspace"
	elif [ "${project_name:0:6}" =  "HedHey" ] ; then 
		workspace="$hey_workspace"
	elif [ "${project_name:0:6}" =  "HedHes" ] ; then 
		workspace="$hes_workspace"
	elif [ "${line:0:4}" =  "fscm" ] ; then 
		workspace="$fscm_workspace"
	else
		echo "unable to find jpr workspace for $project_name"
		continue
	fi
	
	echo ""
	echo -n "Making potential output jars mkprivate..."
	find $AVR/fusionapps/ -name "*${project_name}*.jar" -exec ade mkprivate {} \;
	echo "Done"
	
	echo "Build all profiles for project $project_name"
	
	`$ojdeploy_tool -profile $profile_name -workspace $workspace -project $project_name -clean | tee -a ojdeploy_out.txt`
	
done < "./projectPaths.txt"
	
