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
viewname=`date +"build%Y%m%d%H%M%S"`
update_bug="Y"
#series_name="FUSIONAPPS_11.1.1.5.1_LINUX.X64"
#series_name="FUSIONAPPS_PT.V2MIBHED_LINUX.X64"
#series_name="FUSIONAPPS_PT.V2MIB_LINUX.X64" 
#series_name="FUSIONAPPS_PT.V2MIBHEDJET_LINUX.X64"
series_name=""
#junit_db_mc="slcak358.us.oracle.com" 
#junit_port="1563" 
#junit_sid="ems7642"
#junit_db_mc="slcak358.us.oracle.com" 
#junit_port="1581" 
#junit_sid="ems2658"
junit_db_mc="indl136102.idc.oracle.com" 
junit_port="1522" 
junit_sid="in136102"
junit_full_suite="N"
run_test="Y"
start_time=`date`
destroy_view="Y"
run_build="Y"
curUser=`whoami`
central_log_dir="/net/den01ghp.us.oracle.com/scratch/share/build_logs"
emma="false"
trans_name=$1

#################################################################################

sendEmail()
{
echo "Sending report to $user." | tee -a $log_dir/${trans_name}.log
cfgFile=~/.Premerge.cfg


email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
if [[ -n $email ]];then
	echo "Reading email id from $cfgFile"  | tee -a $log_dir/${trans_name}.log
	echo "Email ID: $email" | tee -a $log_dir/${trans_name}.log
	echo "Sending email.." | tee -a $log_dir/${trans_name}.log

	subject="Build report for $trans_name -- $success"
	build_details=`tail --lines=13 $log_dir/build-report.log`
	# attachments="-a /home/${curUser}/build_logs/${trans_name}/build-report.log   -a /home/${curUser}/build_logs/${trans_name}/build-report.html"
	attachments=""
	if [ -f $log_dir/${trans_name}_build-report.html ]; then
		attachments=" -a ${log_dir}/${trans_name}_build-report.html"
	fi
	mail_text="Build details:"			
	mail_text="$mail_text"$'\n'************
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text Log access: http://den01ghp.us.oracle.com/build_logs_central/${viewname} "$'\n' 
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text $build_details"
	
	if [ -f $log_dir/${trans_name}_HER_test-report.html ]; then
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text -------------------------------------------------------------------------"
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text HER Test Details"
		mail_text="$mail_text"$'\n'***************** 
		mail_text="$mail_text $testresult_HER"
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text HER Test Details"
		mail_text="$mail_text"$'\n'
		compile_errors=""
		compile_errors=`cat /home/${curUser}/build_logs/${viewname}/${trans_name}_HER_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then		
			mail_text="$mail_text"$'\n'
			mail_text="$mail_text !!!! Compile Errors !!!"
			mail_text="$mail_text $compile_errors"
			mail_text="$mail_text"$'\n'
		fi
		attachments="$attachments -a /home/${curUser}/build_logs/${viewname}/${trans_name}_HER_test-report.html"
	fi
	if [ -f $log_dir/${trans_name}_HES_test-report.html ]; then
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text -------------------------------------------------------------------------"
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text HES Test Details"
		mail_text="$mail_text"$'\n'***************** 
		mail_text="$mail_text $testresult_HES"
		mail_text="$mail_text"$'\n'
		compile_errors=""
		compile_errors=`cat /home/${curUser}/build_logs/${viewname}/${trans_name}_HES_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then
			mail_text="$mail_text"$'\n'
			mail_text="$mail_text !!!! Compile Errors !!!"
			mail_text="$mail_text $compile_errors"
			mail_text="$mail_text"$'\n'
		fi
		attachments="$attachments -a /home/${curUser}/build_logs/${viewname}/${trans_name}_HES_test-report.html"
	fi
	if [ -f $log_dir/${trans_name}_HEY_test-report.html ]; then
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text -------------------------------------------------------------------------"
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text"$'\n'
		mail_text="$mail_text HEY Test Details"
		mail_text="$mail_text"$'\n'***************** 
		mail_text="$mail_text $testresult_HEY"
		mail_text="$mail_text"$'\n'
		compile_errors=""
		compile_errors=`cat /home/${curUser}/build_logs/${viewname}/${trans_name}_HEY_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then
			mail_text="$mail_text"$'\n'
			mail_text="$mail_text !!!! Compile Errors !!!"
			mail_text="$mail_text $compile_errors"
			mail_text="$mail_text"$'\n'
		fi
		attachments="$attachments -a /home/${curUser}/build_logs/${viewname}/${trans_name}_HEY_test-report.html"
	fi
	
 			
	echo "$mail_text" | mutt  $email $attachments -s "$subject" $cc_mail 
else
	echo "Could not find user's email. Email notification cannot be sent" | tee -a $log_dir/${trans_name}.log
fi

}


destroyView()
{
if [ "$destroy_view" = "Y" ]; then
	echo -n "Destroying build view $viewname..." | tee -a $log_dir/${trans_name}.log
	`ade destroyview $viewname  -no_ask > $log_dir/destroyview.log `
	echo "Done." | tee -a $log_dir/${trans_name}.log
else
	echo "$viewname not destroyed" | tee -a $log_dir/${trans_name}.log
fi
}

displayEndSummary()
{
end_time=`date`
echo "Ended processing at $end_time" | tee $log_dir/${trans_name}.log

script_end_time=$(date +%s)
script_elapsed_time=$(($script_end_time - $script_start_time))
secs=$((  script_elapsed_time % 60    ))  
mins=$((  ( script_elapsed_time / 60 ) % 60    ))  
hrs=$((  script_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`

echo "" | tee -a $log_dir/${trans_name}.log
echo "Execution duration $elapsed_time_formatted" | tee -a $log_dir/${trans_name}.log
}


copyLogsToCentral() 
{
cp -r "$log_dir" "$central_log_dir" 
echo "Logs are available at $central_log_dir and http://den01ghp.us.oracle.com/build_logs_central/${viewname}"
}

handleInterrupt()
{
echo "User intrrupted the script. Exiting cleanly..." | tee -a $log_dir/${1}.log
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
echo "**************** Transaction Builder & Tester *****************************"
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
`ade describetrans $1 &> $log_dir/describetrans.log`

invalid_trans=""
invalid_trans=`cat  $log_dir/describetrans.log | grep "not found in ADE"`
if [ "$invalid_trans" != "" ]; then
	echo "$invalid_trans" | tee -a $log_dir/${1}.log
	exit
fi

if [ "$series_name" = "" ]; then
	series_name=`cat  $log_dir/describetrans.log | grep "BASE_LABEL" | cut -d":" -f2 | cut -d"_" -f1,2,3 | tr -d ' '`
fi

if [ "$series_name" = "" ]; then
	echo "Could not find series name. Exiting.." | tee -a $log_dir/${1}.log
	exit
else
	echo "Found series name from transaction: $series_name" | tee -a $log_dir/${1}.log
fi

# set LRG db values based on series name - we know series for R13 and R13.6 currently
if [ "$series_name" = "FUSIONAPPS_PT.V2MIBHEDJET_LINUX.X64" ]; then
	junit_db_mc="slcak358.us.oracle.com" 
	junit_port="1581" 
	junit_sid="ems2658"
elif [ "$series_name" = "FUSIONAPPS_PT.V2MIBHED_LINUX.X64" ]; then
	junit_db_mc="slcak358.us.oracle.com" 
	junit_port="1564" 
	junit_sid="ems1543"
fi

junit_db_mc="indl136102.idc.oracle.com" 
junit_port="1522" 
junit_sid="in136102"

#echo "Transaction name: $1. Started processing at $script_start_time" | tee -a $log_dir/${1}.log

bugNo=`ade describetrans $1 -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
if [ "$bugNo" = "" ]; then
	echo "Could not determine bug number from transaction. Reports wont be uploaded to bugDB" | tee -a $log_dir/${1}.log
	update_bug="N"
else
	echo "Found bug number $bugNo" | tee -a $log_dir/${1}.log
fi

cc_mail=""
length="$#"
if [  "$length" -gt 1 ]  ;then
	echo "Reading arguments.."
	index=2						
	for var in "$@"
	do 
		if [ "$var" =  "no_upload" ] ; then  
			update_bug="N"
			echo "Based on argument provided to script, build report upload to bugDB is turned off" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "full_test" ] ; then  
			junit_full_suite="Y"
			echo "Based on argument provided to script, full product test suite will be run if applicable" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "no_test" ] ; then  
			run_test="N"
			echo "Based on argument provided to script, junit test will not be executed" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "quick_build" ] ; then  
			quick_build="Y"
			echo "Based on argument provided to script, quick build will be run if applicable" | tee -a $log_dir/${1}.log
		elif [ "${var: -11}" =  "@oracle.com" ] ; then  #this is most likely an email address
			cc_mail="$cc_mail -c $var"
			echo "Based on argument provided to script, notification email will cc $var" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "retain_view" ] ; then  
			destroy_view="N"
			echo "Based on argument provided to script, temp view will not be destroyed" | tee -a $log_dir/${1}.log	
		elif [ "$var" =  "no_build" ] ; then  
			run_build="N"
			echo "Based on argument provided to script, build will not be executed" | tee -a $log_dir/${1}.log	
		elif [ "${var:0:11}" =  "FUSIONAPPS_" ] ; then   #this is very likely to be series name, use this series for view
			series_name="$var"
			echo "Based on argument provided to script, series used will be $var" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "emma" ] ; then   #enabel emma report
			emma="true"
			echo "Based on argument provided to script, emma coverage will be enabled" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "ems7642" ] ; then   
			junit_db_mc="slcak358.us.oracle.com" 
			junit_port="1563" 
			junit_sid="ems7642"
			echo "Based on argument provided to script, junit DB set to $var " | tee -a $log_dir/${1}.log
		elif [ "$var" =  "r13.6db" ] ; then  
			junit_db_mc="slcak358.us.oracle.com" 
			junit_port="1581" 
			junit_sid="ems2658"
			echo "Based on argument provided to script, junit DB set to $var - ems2658 " | tee -a $log_dir/${1}.log
		elif [ "$var" =  "r13db" ] ; then  
			junit_db_mc="slcak358.us.oracle.com" 
			junit_port="1564" 
			junit_sid="ems1543"
			echo "Based on argument provided to script, junit DB set to $var - ems1543" | tee -a $log_dir/${1}.log
		fi
	done
fi



echo ""
echo "Build will be run on ade series $series_name"
echo "Junit DB is ${junit_db_mc}:${junit_port}/${junit_sid} "
echo ""

#if [ "$cc_mail" != "" ]; then
#	cc_mail=" -c $cc_mail"
#fi

task_start_time=$(date +%s)
echo -n "Creating build view $viewname..." | tee -a $log_dir/${1}.log
`ade createview $viewname -series $series_name -latest > $log_dir/createview.log`
#`ade createview $viewname -label FUSIONAPPS_PT.INTHED_LINUX.X64_160513.1200.S > $log_dir/createview.log`
out_file=""
out_file=`cat $log_dir/createview.log | grep "ade ERROR:"`
if [ "$out_file" != "" ]; then
	echo "Error during createview" | tee -a $log_dir/${1}.log
	echo "$out_file" | tee -a $log_dir/${1}.log
	exit
fi
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted"  | tee -a $log_dir/${1}.log



#`cp -fv /home/machack/workaround/build-*.xml ~/view_storage/${user}_${viewname}/fusionapps/hed/`

if [ "$quick_build" = "Y" ]; then
	run_HEY_build="N"
	run_HES_build="N"
	run_HER_build="N"
	run_build_file=""
	while IFS='' read -r line || [[ -n "$line" ]]; do
		build_path=`echo "$line" | awk '{print $1}'`
		build_file=`echo "$line" | awk '{print $3}'`
		trans_match=""
		trans_match=`cat $log_dir/describetrans.log | grep ${build_path} | head -1`
		if [ "$trans_match" != "" ]; then
			echo "Found object in transaction related to build file $build_file" | tee -a $log_dir/${1}.log			
			if [ "$build_file" = "build-campusCommunity.xml" ]; then
				run_HEY_build="Y"
				run_build_file="$build_file"
			elif [ "$build_file" = "build-financialsManagement.xml" ]; then
				run_HES_build="Y"
				run_build_file="$build_file"			
			elif [ "$build_file" = "build-recordsManagement.xml" ]; then
				run_HER_build="Y"
				run_build_file="$build_file"			
			fi
		fi
	done < "/home/${user}/scripts/scripts_build.conf"
	
	# run quick build only if one application's files are modified
	if [ "$run_HEY_build" = "Y" ] && [ "$run_HES_build" = "Y" ] && [ "$run_HER_build" = "Y" ]; then
		quick_build="N" 
	elif [ "$run_HEY_build" = "Y" ] && [ "$run_HES_build" = "Y" ] && [ "$run_HER_build" = "N" ]; then
		quick_build="N"
	elif [ "$run_HEY_build" = "Y" ] && [ "$run_HES_build" = "N" ] && [ "$run_HER_build" = "Y" ]; then
		quick_build="N" 
	elif [ "$run_HEY_build" = "N" ] && [ "$run_HES_build" = "Y" ] && [ "$run_HER_build" = "Y" ]; then
		quick_build="N" 
	elif [ "$run_HEY_build" = "N" ] && [ "$run_HES_build" = "N" ] && [ "$run_HER_build" = "N" ]; then
		quick_build="N" 		
	fi
	
	if [ "$quick_build" = "N" ]; then
		echo "Quick build not possible. More than one application's files are in the transaction"
	else
		echo "Quick build will be run using build file $run_build_file"
		# delete jars from the corresponding jlib folders of the application as ant clean will not be used in the build
		if [ "$run_HEY_build" = "Y" ]; then
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/AdfHedHey*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/fscm/AdfHedHey*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/jlib/AdfHedHey*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/components/campusCommunity/jlib/*`
		elif [ "$run_HES_build" = "Y" ]; then
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/AdfHedHes*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/fscm/AdfHedHes*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/jlib/AdfHedHes*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/components/financialsManagement/jlib/*`
		elif [ "$run_HER_build" = "Y" ]; then
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/AdfHedHer*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/jlib/fscm/AdfHedHer*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/jlib/AdfHedHer*`
			`rm -f ~/view_storage/${user}_${viewname}/fusionapps/hed/components/recordsManagement/jlib/*`
		fi
	fi
fi

task_start_time=$(date +%s)
echo -n "Grabbing transaction $1..." | tee -a $log_dir/${1}.log
`ade useview $viewname -silent -exec "ade grabtrans $1 &> $log_dir/grabtrans.log" &> $log_dir/useview.log`
task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log


if [ "$run_build" = "Y" ]; then
	task_start_time=$(date +%s)
	if [ "$quick_build" = "Y" ]; then
		echo -n "Running quick build for transaction $1..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant build build-report -f hed/${run_build_file} &> $log_dir/build-report.log" &> $log_dir/useview.log`
	else
		echo -n "Running build for transaction $1..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant clean build build-report -f hed/build.xml &> $log_dir/build-report.log" &> $log_dir/useview.log`
	fi
	task_end_time=$(date +%s)
	getElapsedTime
	echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log

	# check if build failed
	build_status=""
	build_status=`tail --lines=30 $log_dir/build-report.log | grep "BUILD FAILED"`
	if [ "$build_status" != "" ]; then
		#build failed. Run build report to get the actual html data
		echo "Build failed. Trying to generate report"  | tee -a $log_dir/${1}.log
		`cp $log_dir/build-report.log $log_dir/build-report_backup.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/*.err  $log_dir/`
		`ade useview $viewname -silent -exec "ant build-report -f hed/build.xml &> $log_dir/build-report.log"`
	fi


	echo "" | tee -a $log_dir/${1}.log
	echo "Build results:" | tee -a $log_dir/${1}.log
	echo "**************"
	buildresult=`tail --lines=13 $log_dir/build-report.log`
	echo "$buildresult" | tee -a $log_dir/${1}.log
	echo "" | tee -a $log_dir/${1}.log
	echo "" | tee -a $log_dir/${1}.log

	# copy the logs and report to the logs directory
	`cp $log_dir/build-report.log $log_dir/${1}_build-report.log`
	`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/build-report.html  $log_dir/${1}_build-report.html`

	success=`tail --lines=13 $log_dir/build-report.log | grep "Status:" | awk '{print $3}'`
	if [ "$success" = "SUCCESS" ] && [ "$update_bug" = "Y" ]; then  # the report shows a successful compile
		echo "Uploading reports to bugDB..." | tee -a $log_dir/${1}.log
		
		`~/scripts/bup.sh $bugNo $log_dir/${1}_build-report.html $log_dir/${1}_build-report.log &> $log_dir/bugDB_upload.log`	
	else
		echo "Compile failed or bug update turned off. Not uploading reports" | tee -a $log_dir/${1}.log
	fi

	if [ "$success" != "SUCCESS" ]; then
		#run_test="N" TODO change after build issues are resolved
		jj="gg"
	fi
fi

#running junits if applicable
task_start_time=$(date +%s)
run_HEY_test="N"
run_HES_test="N"
run_HER_test="N"
if [ "$run_test" = "Y" ]; then
	echo "Determining Junit tests to run..." | tee -a $log_dir/${1}.log
	test_projects=""
	while IFS='' read -r line || [[ -n "$line" ]]; do
    	#echo "Text read from file: $line"
		test_path=`echo "$line" | awk '{print $1}'`
		test_project=`echo "$line" | awk '{print $3}'`
		build_file=`echo "$line" | awk '{print $5}'`
		trans_match=""
		trans_match=`cat $log_dir/describetrans.log | grep ${test_path} | head -1`
		#echo "test_path = $test_path. test_project = $test_project. build_file = $build_file. trans_match = $trans_match"
		if [ "$trans_match" != "" ]; then
			echo "Found object related to project $test_project and build file $build_file" | tee -a $log_dir/${1}.log			
			if [ "$build_file" = "build-campusCommunity.xml" ]; then
				run_HEY_test="Y"
				if [ "$test_projects_HEY" = "" ]; then
					test_projects_HEY="$test_project"
				else
					# do nothing for now, only one project execution is supported right now
					test_projects_HEY="${test_projects_HEY}\|${test_project}"
					#echo "Skipping project $test_project"
				fi
			elif [ "$build_file" = "build-financialsManagement.xml" ]; then
				run_HES_test="Y"
				if [ "$test_projects_HES" = "" ]; then
					test_projects_HES="$test_project"
				else
					# do nothing for now, only one project execution is supported right now
					test_projects_HES="${test_projects_HES}\|${test_project}"
					#echo "Skipping project $test_project"
				fi
			elif [ "$build_file" = "build-recordsManagement.xml" ]; then
				run_HER_test="Y"
				if [ "$test_projects_HER" = "" ]; then
					test_projects_HER="$test_project"
				else
					# do nothing for now, only one project execution is supported right now
					test_projects_HER="${test_projects_HER}\|${test_project}"
					#echo "Skipping project $test_project"
				fi
			fi
		fi
	done < "/home/${user}/scripts/scripts_junits.conf"

	if [ "$run_HEY_test" = "N" ] && [ "$run_HES_test" = "N" ] && [ "$run_HER_test" = "N" ] ; then
		echo "Test projects could not be determined. Objects in the transaction do not have corresponding test suites."
	fi

	if [ "$run_HEY_test" = "Y" ]; then
		# delete any remnants from previos test runs
		`rm ~/view_storage/${user}_${viewname}/fusionapps/hed/TEST*`
		
		task_start_time=$(date +%s)
		if [ "$junit_full_suite" = "N" ]; then			
			echo "Test projects to run for HEY are $test_projects_HEY" | tee -a $log_dir/${1}.log
			echo -n "Running HEY Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Dtest.project=$test_projects_HEY -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-campusCommunity.xml test test-report &> $log_dir/HEY_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime	
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		else
			echo "All test projects in HEY wil be run" | tee -a $log_dir/${1}.log
			echo -n "Running HEY Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-campusCommunity.xml test test-report &> $log_dir/HEY_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime			
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		fi
		
		echo "" | tee -a $log_dir/${1}.log
		echo "HEY Test results:" | tee -a $log_dir/${1}.log
		echo "******************"
		testresult_HEY=`tail --lines=12 $log_dir/HEY_test-report.log`
		echo "$testresult_HEY" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		compile_errors=""
		compile_errors=`cat $log_dir/HEY_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then
			echo " !!! compile errors !!!" | tee -a $log_dir/${1}.log
			echo "$compile_errors" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
		fi

		`cp $log_dir/HEY_test-report.log $log_dir/${1}_HEY_test-report.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/test-report.html  $log_dir/${1}_HEY_test-report.html` 
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage/  $log_dir/`
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/_files/  $log_dir/`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage*  $log_dir/`
		
		# upload reports to bugDB
		if [ "$update_bug" = "Y" ]; then
			echo -n "Uploading HEY reports to bugDB..." | tee -a $log_dir/${1}.log 			
			`~/scripts/bup.sh $bugNo $log_dir/${1}_HEY_test-report.html $log_dir/${1}_HEY_test-report.log &> $log_dir/bugDB_upload.log`
			echo "Done."
		fi
	fi
	if [ "$run_HES_test" = "Y" ]; then
		# delete any remnants from previos test runs
		`rm ~/view_storage/${user}_${viewname}/fusionapps/hed/TEST*`
		
		task_start_time=$(date +%s)
		if [ "$junit_full_suite" = "N" ]; then
			echo "Test projects to run for HES are $test_projects_HES" | tee -a $log_dir/${1}.log
			echo -n "Running HES Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Dtest.project=$test_projects_HES -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-financialsManagement.xml test test-report &> $log_dir/HES_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime	
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		else
			echo "All test projects in HES wil be run" | tee -a $log_dir/${1}.log
			echo -n "Running HES Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-financialsManagement.xml test test-report &> $log_dir/HES_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime	
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		fi
		
		echo "" | tee -a $log_dir/${1}.log
		echo "HES Test results:" | tee -a $log_dir/${1}.log
		echo "******************"
		testresult_HES=`tail --lines=12 $log_dir/HES_test-report.log`
		echo "$testresult_HES" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		compile_errors=""
		compile_errors=`cat $log_dir/HES_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then
			echo " !!! compile errors !!!" | tee -a $log_dir/${1}.log
			echo "$compile_errors" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
		fi

		`cp $log_dir/HES_test-report.log $log_dir/${1}_HES_test-report.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/test-report.html  $log_dir/${1}_HES_test-report.html` 
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage/  $log_dir/`
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/_files/  $log_dir/`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage*  $log_dir/`
		
		# upload reports to bugDB
		if [ "$update_bug" = "Y" ]; then
			echo -n "Uploading HES reports to bugDB..." | tee -a $log_dir/${1}.log 

			`~/scripts/bup.sh $bugNo $log_dir/${1}_HES_test-report.html $log_dir/${1}_HES_test-report.log &> $log_dir/bugDB_upload.log`
			echo "Done."
		fi
	fi
	if [ "$run_HER_test" = "Y" ]; then
		# delete any remnants from previos test runs
		`rm ~/view_storage/${user}_${viewname}/fusionapps/hed/TEST*`
		
		task_start_time=$(date +%s)
		if [ "$junit_full_suite" = "N" ]; then
			echo "Test projects to run for HER are $test_projects_HER" | tee -a $log_dir/${1}.log
			echo -n "Running HER Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Dtest.project=$test_projects_HER -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-recordsManagement.xml test test-report &> $log_dir/HER_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime	
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		else
			echo "All test projects in HER wil be run" | tee -a $log_dir/${1}.log
			echo -n "Running HER Junits..." | tee -a $log_dir/${1}.log
			`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Demma.enabled=$emma -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-recordsManagement.xml test test-report &> $log_dir/HER_test-report.log"`
			task_end_time=$(date +%s)
			getElapsedTime	
			echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
		fi
		
		echo "" | tee -a $log_dir/${1}.log
		echo "HER Test results:" | tee -a $log_dir/${1}.log
		echo "******************"
		testresult_HER=`tail --lines=12 $log_dir/HER_test-report.log`
		echo "$testresult_HER" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		echo "" | tee -a $log_dir/${1}.log
		compile_errors=""
		compile_errors=`cat $log_dir/HER_test-report.log | grep -B 1 "\[custom:test\] Error("`
		if [ "$compile_errors" != "" ]; then
			echo " !!! compile errors !!!" | tee -a $log_dir/${1}.log
			echo "$compile_errors" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
			echo "" | tee -a $log_dir/${1}.log
		fi
		
		`cp $log_dir/HER_test-report.log $log_dir/${1}_HER_test-report.log`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/test-report.html  $log_dir/${1}_HER_test-report.html` 
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage/  $log_dir/`
		`cp -r ~/view_storage/${user}_${viewname}/fusionapps/hed/_files/  $log_dir/`
		`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/coverage*  $log_dir/`

		# upload reports to bugDB
		if [ "$update_bug" = "Y" ]; then
			echo -n "Uploading HER reports to bugDB..." | tee -a $log_dir/${1}.log 
			
			`~/scripts/bup.sh $bugNo $log_dir/${1}_HER_test-report.html $log_dir/${1}_HER_test-report.log &> $log_dir/bugDB_upload.log`
			echo "Done."
		fi
	fi
	
else
	echo "Junit tests skipped." | tee -a $log_dir/${1}.log
fi
task_end_time=$(date +%s)
getElapsedTime
echo "JUnits tests task completed in $elapsed_time_formatted"

# copy logs to central shared folder
copyLogsToCentral


sendEmail

if [ "$success" != "SUCCESS" ]; then #save the build logs and reports for later examination
	#zip -q $log_dir/buildlogs ~/view_storage/${user}_${viewname}/fusionapps/hed/*
	`cp  ~/view_storage/${user}_${viewname}/fusionapps/hed/*.err $log_dir`
	destroy_view="N"	
fi

destroyView

displayEndSummary

