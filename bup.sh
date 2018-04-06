#!/bin/bash

# bup - Bug Uploader
# Author: Manish Chacko
# Created on: 16-Nov-2015
# Last updated: 21-Nov-2015
# Version 0.2
# 
# bup.sh {bugnumber} {file1} {files2}...
# all arguments are optional and could be in any order
#
# This script will upload files to bugsftp based on command line arguments. 
# If no arguments are specified, it uses the current ade view's transaction name to figure out the bug number
# if no files are specified, it check for the following files in current directory to upload:
# build-report.html, build-report.html, test-report.html, test-report.log 

############ Change log #############################################
#
# 21-Nov-2015: Changed the logic to get bug number from describetrans instead of transaction name
#
#################################################################

getBugNumber ()
{
 #check if the command is run from a view
 view="$(ade pwv)"
 if [ "$view" = "ade ERROR: Not in a view." ]; then
	echo "Not is a view. Please run this command inside a view or specify a bug number"
	exit
 fi
	
# echo "Trying to figure out the bug number from transaction name..."
# bugNbr="$(ade pwv | grep 'VIEW_TXN_NAME' | tail -c 9)" 
 bugNbr=`ade describetrans -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
 echo -e "Found bug number: \e[1m$bugNbr\e[0m" 
	
 reNbr='^[0-9]+$' 
 if ! [[ $bugNbr =~ $reNbr ]] ; then
	echo "The determined bug number is invalid. Exiting"
	exit
fi
}


# check files to upload
fileList=""
length="$#"
bugNbrSpecified="N"
re='^[0-9]+$'
bugNbr="" 

if [  "$length" -gt 0 ]  ;then
	#echo "Reading arguments.."
	index=1						
	for var in "$@"
	do 
		if [ "${#var}" -eq 8 ] && [[ $var =~ $re ]]  ; then
			# This could be bug number
			bugNbrSpecified="Y"
			bugNbr="$var"
			echo -e "Found bug number: \e[1m$var\e[0m"
			continue							
		elif [ -f "$var" ] ; then  
			echo "Found file $var in curent directory, adding to list for upload"
			fileList="$fileList put $var;"
		else
			echo "File $var not found, skipping"
		fi		
	done
fi

# figure out the bug number from the transaction name if its not specified as an argument
if [ "$bugNbrSpecified" = "N" ] ; then
	getBugNumber
fi

if [ "$bugNbr" = "" ] ; then
	echo "Cannot find bug number. Exiting.. "
	exit
fi

if [ "$fileList" = "" ] ; then
	echo "Checking for default files to upload"
	if [ -f ./build-report.html ]; then #upload default files
			fileList="$fileList put build-report.html;" 
	fi
	if [ -f ./build-report.log ]; then
			fileList="$fileList put build-report.log;" 
	fi
	if [ -f ./test-report.html ]; then
			fileList="$fileList put test-report.html;" 
	fi
	if [ -f ./test-report.log ]; then
			fileList="$fileList put test-report.log;" 
	fi

	if ! [ "$fileList" = "" ] ; then
		prompt="Y"
	fi
fi

if [ "$fileList" = "" ] ; then
	echo "Did not find any files to upload, exiting."
	exit
else
	echo -e "Files to upload: \e[1m$fileList\e[0m"
	if [ "$prompt" = "Y" ] ; then
		read -p 'Continue? (Y/n): ' cont
		if [ "$cont" = "N" ] || [ "$cont" = "n" ] ; then
			exit
		fi
	fi	
fi

emailid="manish.chacko@oracle.com"
password="***REMOVED***"
#read -sp 'BugDB password: ' password

#echo "Command: lftp sftp://$emailid:$password@bugsftp.us.oracle.com -e cd $bugNbr;$fileList bye "; 

lftp sftp://$emailid:$password@bugsftp.us.oracle.com -e "cd $bugNbr;$fileList bye"
