#!/bin/bash

# 12cBuilder - Runs the 12C migration framework and build HED applications a new ADE view on family branch
# Emails the build report and test report to the machine owner on completion 
# 
#
# Author: Manish Chacko
# Created on: 05-Sep-2018
# Last updated: 05-Sep-2018
# Version 0.1
# 
# Usage:
# 12cBuilder.sh 
#
#
# Logs are stored in $HOME/build_logs directory


script_start_time=$(date +%s)

user=`whoami`
viewname=`date +"build12c%Y%m%d%H%M%S"`
update_bug="Y"
series_name="FUSIONAPPS_PT.V2MIBFPHGOLD_LINUX.X64"
#junit_db_mc="slcak358.us.oracle.com" 
#junit_port="1563" 
#junit_sid="ems7642"
junit_db_mc="slcak358.us.oracle.com" 
junit_port="1581" 
junit_sid="ems2658"
junit_full_suite="N"
run_test="Y"
start_time=`date`
destroy_view="Y"
run_build="Y"
curUser=`whoami`
central_log_dir="/net/den01ghp.us.oracle.com/scratch/share/build_logs"
script_dir="/home/${curUser}/scripts"
emma="false"
trans_name=$1
success=""

#################################################################################

sendEmail()
{
echo "Sending report to $user." | tee -a $log_dir/email.log
cfgFile=~/.Premerge.cfg


email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
if [[ -n $email ]];then
	echo "Reading email id from $cfgFile"  | tee -a $log_dir/email.log
	echo "Email ID: $email" | tee -a $log_dir/email.log
	echo "Sending email.." | tee -a $log_dir/email.log

	subject="12c migration report for label $view_label -- $success"
	build_details=`tail --lines=13 $log_dir/build-report.log`
	attachments=""
	if [ -f $log_dir/build-report.html ]; then
		attachments=" -a ${log_dir}/build-report.html"
	fi
	mail_text="Build details:"			
	mail_text="$mail_text"$'\n'************
	mail_text="$mail_text"$'\n' 
        mail_text="$mail_text Task started at: $task_start_time"$'\n' 
        mail_text="$mail_text Task total duration: $elapsed_time_formatted"$'\n'
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text Log access: http://den01ghp.us.oracle.com/build_logs_central/${viewname} "$'\n' 
	mail_text="$mail_text"$'\n'        
	mail_text="$mail_text $build_details"
	
 			
	echo "$mail_text" | mutt  $email $attachments -s "$subject" $cc_mail 
else
	echo "Could not find user's email. Email notification cannot be sent" | tee -a $log_dir/email.log
fi

}


destroyView()
{
if [ "$destroy_view" = "Y" ]; then
	echo -n "Destroying build view $viewname..." | tee -a $log_dir/destroyview.log
	`ade destroyview $viewname  -no_ask > $log_dir/destroyview.log `
	echo "Done." | tee -a $log_dir/destroyview.log
else
	echo "$viewname not destroyed" | tee -a $log_dir/destroyview.log
fi
}

displayEndSummary()
{
end_time=`date`
echo "Ended processing at $end_time" | tee $log_dir/useview.log

script_end_time=$(date +%s)
script_elapsed_time=$(($script_end_time - $script_start_time))
secs=$((  script_elapsed_time % 60    ))  
mins=$((  ( script_elapsed_time / 60 ) % 60    ))  
hrs=$((  script_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`

echo "" | tee -a $log_dir/useview.log
echo "Execution duration $elapsed_time_formatted" | tee -a $log_dir/useview.log
}


copyLogsToCentral() 
{
cp -r "$log_dir" "$central_log_dir" 
echo "Logs are available at $central_log_dir and http://den01ghp.us.oracle.com/build_logs_central/${viewname}"
}

handleInterrupt()
{
echo "User interrupted the script. Exiting cleanly..." | tee -a $log_dir/useview.log
copyLogsToCentral
sendEmail
destroyView
displayEndSummary
exit
}

getElapsedTime () 
{
task_elapsed_time=$(($task_end_time - $task_start_time))
secs=$((  task_elapsed_time % 60    ))  
mins=$((  ( task_elapsed_time / 60 ) % 60    ))  
hrs=$((  task_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`
}

#######################################################################################################################'


trap handleInterrupt 1 2 15


echo ""
echo "***************************************************************************"
echo "************************* 12c Builder  ************************************"
echo ""
echo ""


#check if the command is run from a view
view="$(ade pwv)"
if [ "$view" != "ade ERROR: Not in a view." ]; then
	echo "Please run this command outside a view."
exit
fi

# create a log directory for the build view
log_dir="/home/${curUser}/build_logs/${viewname}"
mkdir -p "$log_dir"
echo "Logs will be stored in location: $log_dir"
echo "Using series $series_name to run MF and build"



task_start_time=$(date +%s)
echo -n "Creating build view $viewname..." | tee -a $log_dir/script.log
`ade createview $viewname -series $series_name -latest > $log_dir/01_createview.log`
out_file=""
out_file=`cat $log_dir/createview.log | grep "ade ERROR:"`
if [ "$out_file" != "" ]; then
	echo "Error during createview" | tee -a $log_dir/00_script.log
	echo "$out_file" | tee -a $log_dir/script.log
	exit
fi
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted"  | tee -a $log_dir/00_script.log

echo "Setting MF env variable - FA_VIRTUAL_ENV"
export FA_VIRTUAL_ENV="true"


# get view label
echo "Getting view label and expanding the files..."
# ade useview $viewname  -exec "ade pwv &> $log_dir/ade_pwv.log ; ade expand -recurse $AVR/fusionapps &> $log_dir/ade_expand.log"
`ade useview $viewname  -exec "ade pwv &> $log_dir/02_ade_pwv.log"`
view_label=`cat $log_dir/02_ade_pwv.log | grep "VIEW_LABEL" | awk '{print $3}'`
echo "View Label	:	$view_label" | tee -a $log_dir/00_script.log

echo "Copying JwsFilesList.txt to ADE view"
`cp -f ${script_dir}/JwsFilesList.txt ~/view_storage/${user}_${viewname}/fusionapps/`

echo -n "Running migration..." | tee -a $log_dir/00_script.log
task_start_time=$(date +%s)
`ade useview $viewname  -exec "ant -f build.xml private-build-migrate -Djwsfileslist="JwsFilesList.txt" -DProcess="migrate" &> $log_dir/MF_console.log" &> $log_dir/03_migration.log` 
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/00_script.log
	
echo -n "Running build..." | tee -a $log_dir/00_script.log
task_start_time=$(date +%s)
`ade useview $viewname  -exec "ant build build-report -f hed/build.xml -Dmodule_clean_old.disable=true &> $log_dir/build-report.log" &> $log_dir/04_build.log`
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/00_script.log

# check if build failed
build_status=""
build_status=`tail --lines=100 $log_dir/build-report.log | grep "BUILD FAILED"`
if [ "$build_status" != "" ]; then
	#build failed. Run build report to get the actual html data
	echo "Build failed. Trying to generate report"  | tee -a $log_dir/00_script.log
	`cp $log_dir/build-report.log $log_dir/build-report_backup.log`
	`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/*.err  $log_dir/`
	`ade useview $viewname -silent -exec "ant build-report -f hed/build.xml &> $log_dir/build-report.log"`
fi


echo "" | tee -a $log_dir/00_script.log
echo "Build results:" | tee -a $log_dir/00_script.log
echo "**************"
buildresult=`tail --lines=13 $log_dir/build-report.log`
echo "$buildresult" | tee -a $log_dir/00_script.log
echo "" | tee -a $log_dir/00_script.log
echo "" | tee -a $log_dir/00_script.log

# copy the logs and report to the logs directory
`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/build-report.html  $log_dir/`

success=`tail --lines=13 $log_dir/build-report.log | grep "Status:" | awk '{print $3}'`


#echo -n "Generating MF reports..." | tee -a $log_dir/00_script.log
#task_start_time=$(date +%s)
#`ade useview $viewname  -exec "../fatools/bin/jdev ojdeployRpt ojdeploy.statusreport.xml &> $log_dir/${view_label}.log ; ../fatools/bin/jdev createBldRpt ${view_label} $log_dir/${view_label}.log &> $log_dir/${view_label}.rpt" &> $log_dir/05_reports.log`
#task_end_time=$(date +%s)
#getElapsedTime
#echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/00_script.log




# copy logs to central shared folder
copyLogsToCentral



#destroyView

displayEndSummary

sendEmail

