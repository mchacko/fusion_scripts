#!/bin/bash

# transBuilder - Build a transaction in a new view
# Emails the build report and test report to the machine owner on completion 
# If the build was successful the build report and log will be uploaded to bugDB: set option no_upload to cancel this action
#
# Author: Manish Chacko
# Created on: 27-Nov-2015
# Last updated: 01-Dec-2015
# Version 0.1
# 
# Usage:
# transBuilder.sh {transaction name} {no_upload} {no_test} {full_test} {quick_build}
#
# {transaction name} must be the first argument. The other arguments can be in any order.
# {no_upload} prevents upload of build and test report to bugDB. If not specified, reports will be uploaded if the build is successful
# {no_test} do not invoke Junits. If not specified, Junits will be executed if build is successful
# {full_test} run the fullproduct test suite rather than the junit project that was determined autmatically by the script. If not specified, only project junit will be executed. 
# {quick_build} The script will try to build using a product's build file rather than HED build file based on the objects in the transaction. If objects from more than one product is present in the transaction, this option is ignored and full build will be run.
#
# Logs are stored in $HOME/build_logs directory
# There is a dependency on the following files in $HOME/scripts directory
# (1) bup.sh
# (2) scripts_junits.conf
# (3) scripts_build.conf


script_start_time=$(date +%s)

user=`whoami`
viewname=`date +"patch%Y%m%d%H%M%S"`
transactionname=`date +"patch%Y%m%d%H%M"`
update_bug="N"
#series_name="FUSIONAPPS_11.1.1.5.1_LINUX.X64"
series_name="FUSIONAPPS_PT.V2MIBHED_LINUX.X64"
#series_name="FUSIONAPPS_PT.V2MIB_LINUX.X64" 
junit_db_mc="slcak359.us.oracle.com" 
junit_port="1535" 
junit_sid="ems10706"
junit_full_suite="N"
run_test="N"
start_time=`date`
destroy_view="Y"
run_build="Y"
curUser=`whoami`
central_log_dir="/net/den01ghp.us.oracle.com/scratch/share/build_logs"
emma="false"
ear_copy_location="/net/slc07pyw.us.oracle.com/scratch/share/r13_pmdit_ears/"
#ear_copy_location="/net/den01ghp.us.oracle.com/scratch/share/patch_ears/"
ear_backup_location="/net/den01ghp.us.oracle.com/scratch/share/patch_ears/PMDIT"

getElapsedTime () 
{
task_elapsed_time=$(($task_end_time - $task_start_time))
secs=$((  task_elapsed_time % 60    ))  
mins=$((  ( task_elapsed_time / 60 ) % 60    ))  
hrs=$((  task_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`
}

echo ""
echo "***************************************************************************"
echo "**************** Transaction Builder & Patcher *****************************"
echo ""
echo ""

if [ "$1" = "" ]; then
	echo "No transaction name provided. Unable to continue"
	exit
fi

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

# save describe trasn to a file for reading later
#`ade describetrans $1 &> $log_dir/describetrans.log`

#invalid_trans=""
#invalid_trans=`cat  $log_dir/describetrans.log | grep "not found in ADE"`
#if [ "$invalid_trans" != "" ]; then
#	echo "$invalid_trans" | tee -a $log_dir/main.log
#	exit
#fi

echo "Started processing at $start_time" > $log_dir/main.log

#bugNo=`ade describetrans $1 -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
#if [ "$bugNo" = "" ]; then
#	echo "Could not determine bug number from transaction. Reports wont be uploaded to bugDB" | tee -a $log_dir/main.log
#	update_bug="N"
#else
#	echo "Found bug number $bugNo" | tee -a $log_dir/main.log
#fi

cc_mail=""
length="$#"
transactions=""
if [  "$length" -gt 1 ]  ;then
	echo "Reading arguments.."
	index=0						
	for var in "$@"
	do 
		if [ "${var: -11}" =  "@oracle.com" ] ; then  #this is most likely an email address
			cc_mail="$cc_mail $var"
			echo "Based on argument provided to script, notification email will cc $var" | tee -a $log_dir/main.log
		elif [ "$var" =  "retain_view" ] ; then  
			destroy_view="N"
			echo "Based on argument provided to script, temp view will not be destroyed" | tee -a $log_dir/main.log	
		elif [ "$var" =  "no_build" ] ; then  
			run_build="N"
			echo "Based on argument provided to script, build will not be executed" | tee -a $log_dir/main.log	
		elif [ "${var:0:11}" =  "FUSIONAPPS_" ] ; then   #this is very likely to be series name, use this series for view
			series_name="$var"
			echo "Based on argument provided to script, series used will be $var" | tee -a $log_dir/main.log		
		else
			#this must be a transaction name
			transNames[$index]=$var
			index=$(($index + 1))
			echo "Found transaction to fetch: $var" | tee -a $log_dir/main.log
		fi
	done
fi


echo "Build will be run on ade series $series_name"

if [ "$cc_mail" != "" ]; then
	cc_mail=" -c $cc_mail"
fi

task_start_time=$(date +%s)
echo ""
echo -n "Creating build view $viewname..." | tee -a $log_dir/main.log
`ade createview $viewname -series $series_name -latest > $log_dir/createview.log`
out_file=""
out_file=`cat $log_dir/createview.log | grep "ade ERROR:"`
if [ "$out_file" != "" ]; then
	echo "Error during createview" | tee -a $log_dir/main.log
	echo "$out_file" | tee -a $log_dir/main.log
	exit
fi
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted"  | tee -a $log_dir/main.log

`cp -fv /home/machack/workaround/build-*.xml ~/view_storage/${user}_${viewname}/fusionapps/hed/`

task_start_time=$(date +%s)
echo ""
echo -n "Begining patch transaction $transactionname..." | tee -a $log_dir/main.log
`ade useview $viewname -silent -exec "ade begintrans $transactionname -no_restore &> $log_dir/begintrans_${transactionname}.log"  &> $log_dir/useview.log`
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log


task_start_time1=$(date +%s)
echo ""
echo "Grabbing transactions..." | tee -a $log_dir/main.log

for x in "${transNames[@]}"
do
	task_start_time=$(date +%s)
	echo -n "Grabbing transaction $x..."
	`ade useview $viewname -silent -exec "ade grabtrans $x &> $log_dir/grabtrans_${x}.log" -exec "ade ciall &> $log_dir/adeciall_${x}.log" &> $log_dir/useview.log`
	

	out_file=""
	out_file=`cat $log_dir/grabtrans_${x}.log | grep "ade ERROR:"`
	if [ "$out_file" != "" ]; then
		echo ""
		echo ""
		echo "Error grabbign transaction $x" | tee -a $log_dir/main.log
		echo "$out_file" | tee -a $log_dir/main.log	
		echo ""	
	else
		task_end_time=$(date +%s)
		getElapsedTime		
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log
	fi		
done

task_start_time=$task_start_time1
task_end_time=$(date +%s)
getElapsedTime
echo "Done grabbing transactions. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log

task_start_time=$(date +%s)
echo -n "Saving transaction $transactionname..." | tee -a $log_dir/main.log
`ade useview $viewname -silent -exec "ade savetrans &> $log_dir/savetrans_${transactionname}.log" &> $log_dir/useview.log`
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log


if [ "$run_build" = "Y" ]; then
	task_start_time=$(date +%s)

	echo -n "Running build..." | tee -a $log_dir/main.log
	`ade useview $viewname -silent -exec "ant clean build build-report -f hed/build.xml &> $log_dir/build-report.log" &> $log_dir/useview.log`

	task_end_time=$(date +%s)
	getElapsedTime
	echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log

	# check if build failed
	build_status=""
	build_status=`tail --lines=30 $log_dir/build-report.log | grep "BUILD FAILED"`
	if [ "$build_status" != "" ]; then
		#build failed. Run build report to get the actual html data
		echo "Build failed. Trying to generate report"  | tee -a $log_dir/main.log
		`cp $log_dir/build-report.log $log_dir/build-report_backup.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/*.err  $log_dir/`
		`ade useview $viewname -silent -exec "ant build-report -f hed/build.xml &> $log_dir/build-report.log"`
	fi


	echo "" | tee -a $log_dir/main.log
	echo "Build results:" | tee -a $log_dir/main.log
	echo "**************"
	buildresult=`tail --lines=13 $log_dir/build-report.log`
	echo "$buildresult" | tee -a $log_dir/main.log
	echo "" | tee -a $log_dir/main.log
	echo "" | tee -a $log_dir/main.log

	# copy the logs and report to the logs directory
	`cp $log_dir/build-report.log $log_dir/${transactionname}_build-report.log`
	`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/build-report.html  $log_dir/${transactionname}_build-report.html`

	success=`tail --lines=13 $log_dir/build-report.log | grep "Status:" | awk '{print $3}'`
	if [ "$success" = "SUCCESS" ]; then  # the report shows a successful compile
		echo ""
		echo "Generating ears..." | tee -a $log_dir/main.log
		task_start_time=$(date +%s)
		`ade useview $viewname -silent -exec "ant ear build-report -f hed/build.xml &> $log_dir/hed_ear.log" &> $log_dir/ear.log`	
		task_end_time=$(date +%s)
		getElapsedTime
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log
		
		echo ""
		echo "Copying ears to shared location..." | tee -a $log_dir/main.log
		task_start_time=$(date +%s)

		`chmod 777 ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedRecordsManagement.ear >> ${log_dir}/main.log`
		`chmod 777 ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedCampusCommunity.ear >> ${log_dir}/main.log`
		`chmod 777 ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedFinancialsManagement.ear >>${log_dir}/main.log`
		`chmod 777 ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedEss.ear >>${log_dir}/main.log`
		
		`mkdir ${ear_backup_location}/${viewname}`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedRecordsManagement.ear  $ear_backup_location/${viewname} -vf >> ${log_dir}/main.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedCampusCommunity.ear  $ear_backup_location/${viewname} -vf >> ${log_dir}/main.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedFinancialsManagement.ear  $ear_backup_location/${viewname} -vf >> ${log_dir}/main.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedEss.ear  $ear_backup_location/${viewname} -vf >> ${log_dir}/main.log`		

		echo ""
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedRecordsManagement.ear  $ear_copy_location -vf >> ${log_dir}/main.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedCampusCommunity.ear  $ear_copy_location -vf >> ${log_dir}/main.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedFinancialsManagement.ear  $ear_copy_location -vf >> ${log_dir}/main.log`	
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/deploy/EarHedEss.ear  $ear_copy_location -vf >> ${log_dir}/main.log`

		`chmod 777 $ear_copy_location/*.ear`

		task_end_time=$(date +%s)
		getElapsedTime
		echo "Done. Task completed in $elapsed_time_formatted" >> $log_dir/main.log
		
		
	
	else
		echo "Compile failed. Not generateing ears" | tee -a $log_dir/main.log
	fi

fi


# copy logs to central shared folder
cp -r "$log_dir" "$central_log_dir" 
echo "Logs are available at $central_log_dir and http://den01ghp.us.oracle.com/build_logs_central/${viewname}"


echo "Sending report to $user." | tee -a $log_dir/main.log
cfgFile=~/.Premerge.cfg


email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
if [[ -n $email ]];then
	echo "Reading email id from $cfgFile"  | tee -a $log_dir/main.log
	echo "Email ID: $email" | tee -a $log_dir/main.log
	echo "Sending email.." | tee -a $log_dir/main.log

	subject="Build report for $transactionname -- $success"
	build_details=`tail --lines=13 $log_dir/build-report.log`
	ear_details=`tail --lines=13 $log_dir/hed_ear.log`
	# attachments="-a /home/${curUser}/build_logs/${1}/build-report.log   -a /home/${curUser}/build_logs/${1}/build-report.html"
	attachments=""
	if [ -f $log_dir/${1}_build-report.html ]; then
		attachments=" -a $log_dir/${transactionname}_build-report.html"
	fi
	
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text The transaction containing the code changes is: $transactionname "$'\n'
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text Build details:"			
	mail_text="$mail_text"$'\n'************
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text Log access: http://den01ghp.us.oracle.com/build_logs_central/${viewname} "$'\n' 
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text $build_details"
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text -------------------------------------------------------------------------"
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text EAR build Details"
	mail_text="$mail_text"$'\n'***************** 
	mail_text="$mail_text $ear_details"	
	
 			
	`echo "$mail_text" | mutt  $email $attachments -s "$subject" $cc_mail` 
else
	echo "Could not find user's email. Email notification cannot be sent" | tee -a $log_dir/main.log
fi


if [ "$success" != "SUCCESS" ]; then #save the build logs and reports for later examination
	#zip -q $log_dir/buildlogs ~/view_storage/${user}_${viewname}/fusionapps/hed/*
	`cp  ~/view_storage/${user}_${viewname}/fusionapps/hed/*.err $log_dir`
	destroy_view="N"	
fi

task_start_time=$(date +%s)
echo -n "Ending transaction $transactionname..." | tee -a $log_dir/main.log
`ade useview $viewname -silent -exec "ade endtrans -no_restore &> $log_dir/savetrans_${transactionname}.log" &> $log_dir/useview.log`
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log


if [ "$destroy_view" = "Y" ]; then
	task_start_time=$(date +%s)
	echo -n "Destroying build view $viewname..." | tee -a $log_dir/main.log
	`ade destroyview $viewname  -no_ask > $log_dir/destroyview.log `
	task_end_time=$(date +%s)
	getElapsedTime
	echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/main.log
else
	echo "$viewname not destroyed" | tee -a $log_dir/main.log
fi


end_time=`date`
`echo "Ended processing at $end_time" >> $log_dir/main.log`

script_end_time=$(date +%s)
script_elapsed_time=$(($script_end_time - $script_start_time))
secs=$((  script_elapsed_time % 60    ))  
mins=$((  ( script_elapsed_time / 60 ) % 60    ))  
hrs=$((  script_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`

echo "" | tee -a $log_dir/main.log
echo "Execution duration $elapsed_time_formatted" | tee -a $log_dir/main.log
 
