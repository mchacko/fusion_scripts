#!/bin/bash

# Script to install hed scripts to a user's home directory
# This will also update ~/.cshrc to add aliases for easier invocation
#

hed_script_repo="/net/slc00slj.us.oracle.com/scratch/share/hed_scripts"
hed_scripts_dir="scripts"
hed_build_logs_dir="build_logs"
user=`whoami`
backup_name=`date +"%Y%m%d%H%M%S"`

echo "*****************************************************************"
echo "******************** HED scripts installer **********************"

if [ -d $hed_script_repo ]; then
	
	# check if the scripts directory exists and create one if not
	if [ -d ~/${hed_scripts_dir} ]; then
		echo "Found scripts directory. Copy will update the scripts in the directory to the latest version." 
	else
		echo "Scripts directory not found. Proceeding to create directory."
		mkdir ~/${hed_scripts_dir}
	fi
	
	if [ -d ~/${hed_build_logs_dir} ]; then
		echo "Build log directory exists."
	else
		echo "Build log directory does not exists. Proceeding to create directory."
		mkdir ~/${hed_build_logs_dir}
	fi
	
	if [ -f ~/${hed_scripts_dir}/bup.sh ]; then
		echo "~/${hed_scripts_dir}/bup.sh will be overwritten with the latest version."
	fi
	if [ -f ~/${hed_scripts_dir}/transBuilder.sh ]; then
		echo "~/${hed_scripts_dir}/transBuilder.sh will be overwritten with the latest version."
	fi
	if [ -f ~/${hed_scripts_dir}/mailme.sh ]; then
		echo "~/${hed_scripts_dir}/mailme.sh will be overwritten with the latest version."
	fi
	if [ -f ~/${hed_scripts_dir}/scripts_junits.conf ]; then
		echo "~/${hed_scripts_dir}/scripts_junits.conf will be overwritten with the latest version."
	fi
	if [ -f ~/${hed_scripts_dir}/scripts_build.conf ]; then
		echo "~/${hed_scripts_dir}/scripts_junits.conf will be overwritten with the latest version."
	fi
	
	`cp -f ${hed_script_repo}/* ~/${hed_scripts_dir}`
	echo "Completed copy operation."
	
	# update cshrc file to add new aliases for these scripts
	if [ -f ~/.cshrc ]; then
		cp ~/.cshrc ~/.cshrc_${backup_name}			
	else
		echo -n "" > ~/.cshrc
		echo "Created new file .cshrc"
	fi
	
	# append to the end of the file. if entry already exists, ignore
	exists=""
	exists=`cat ~/.cshrc | grep "bup"`
	if [ "$exists" != "" ]; then
		echo "Found bup already added to .cshrc, skipping"
	else
		echo "alias bup '/home/${user}/scripts/bup.sh'" >> ~/.cshrc
		echo "Added alias bup to .cshrc"
	fi
	exists=""
	exists=`cat ~/.cshrc | grep "transBuilder"`
	if [ "$exists" != "" ]; then
		echo "Found transBuilder already added to .cshrc, skipping"
	else
		echo "alias transBuilder '/home/${user}/scripts/transBuilder.sh'" >> ~/.cshrc
		echo "Added alias transBuilder to .cshrc"
	fi
	exists=""
	exists=`cat ~/.cshrc | grep "mailme"`
	if [ "$exists" != "" ]; then
		echo "Found mailme already added to .cshrc, skipping"
	else
		echo "alias mailme '/home/${user}/scripts/mailme.sh'" >> ~/.cshrc
		echo "Added alias mailme to .cshrc"
	fi
	
	echo "Installation script completed."
	
else
	echo "Unable to find the hed scripts repository. Please check with manish.chacko@oracle.com"
fi
