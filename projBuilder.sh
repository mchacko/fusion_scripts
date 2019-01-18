#!/bin/bash

# projBuilder - Builds a project without the need to launch jdev
#
# Author: Manish Chacko
# Created on: 30-Aug-2016
# Last updated: 30-Aug-2016
# Version 0.1
# 
# Usage:
# projBuilder.sh {project name} 
#
# {project name} Name of the project in jdeveloper ex: HedHerCurriculumRegistryModel
#


echo ""
echo "***************************************************************************"
echo "*********************** Project Builder  **********************************"
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
workspace=""
var="$1"
log_location=""

if [ "${var:0:6}" =  "HedHer" ] ; then 
	workspace="$her_workspace"
elif [ "${var:0:6}" =  "HedHey" ] ; then 
	workspace="$hey_workspace"
elif [ "${var:0:6}" =  "HedHes" ] ; then 
	workspace="$hes_workspace"
else
	echo "Unable to process project $var. Its not an HED project or it does not confirm to naming standards."
	echo "Please provide project name like HedHerCurriculumRegistryModel"
	exit
fi

#profile_name="${var:5}"
profile_name="*${var}*"

echo "Profile name is: $profile_name"
echo "Workspace is $workspace"
echo "ojdeploy tool is: $ojdeploy_tool"
wildcard1="Adf${var}*"
wildcard2="Svc${var}*"

echo ""
echo -n "Making potential output jars mkprivate..."
find $AVR/fusionapps/ -name "*${var}*.jar" -exec ade mkprivate {} \;
echo "Done"

#make the output jar file private else iojdeploy will fail in the ebd due to read-only filesystem error
#`ade mkprivate $AVR/fusionapps/jlib/${wildcard1}`
#`ade mkprivate $AVR/fusionapps/hed/jlib/${wildcard1}`
#`ade mkprivate $AVR/fusionapps/hed/components/recordsManagement/jlib/${wildcard1}`
#`ade mkprivate $AVR/fusionapps/hed/components/campusCommunity/jlib/${wildcard1}`
#`ade mkprivate $AVR/fusionapps/hed/components/financialsManagement/jlib/${wildcard1}`

`$ojdeploy_tool -profile $profile_name -workspace $workspace -project $var -clean | tee ojdeploy_out.txt`
