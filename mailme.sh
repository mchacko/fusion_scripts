#!/bin/bash

# Script to send an email to the current logged in user
#
#

cfgFile=~/.Premerge.cfg
curUser=`whoami`

email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
 if [[ -n $email ]];then
	echo "Reading email id from $cfgFile" | tee -a $outfile
	echo "Email ID: $email"
else
	echo "mailme: Could not find user's email. Exiting.."
	exit
 fi

#check arguments
length="$#"
starttime=$(date)
build_report="$ADE_VIEW_ROOT/fusionapps/hed/build-report.html"
build_log="$ADE_VIEW_ROOT/fusionapps/hed/build-report.log"
test_report="$ADE_VIEW_ROOT/fusionapps/hed/test-report.html"
test_log="$ADE_VIEW_ROOT/fusionapps/hed/test-report.log"
test_report_her="$ADE_VIEW_ROOT/fusionapps/hed/her_test-report.html"
test_log_her="$ADE_VIEW_ROOT/fusionapps/hed/her_test-report.log"
test_report_hes="$ADE_VIEW_ROOT/fusionapps/hed/hes_test-report.html"
test_log_hes="$ADE_VIEW_ROOT/fusionapps/hed/hes_test-report.log"
test_report_hey="$ADE_VIEW_ROOT/fusionapps/hed/hey_test-report.html"
test_log_hey="$ADE_VIEW_ROOT/fusionapps/hed/hey_test-report.log"
hostname=`hostname -s`

if [  "$length" -gt 0 ]  ;then
	echo "Reading arguments.."
	index=1						
	for var in "$@"
	do 
		if [ "$var" = "reports" ]; then
			
			subject="Build report / Test report completed by $starttime"
			#build_details=`tail --lines=13 $build_log`
			#test_details=`tail --lines=12 $test_log`
			attachments=""

			if [ -f "$build_log" ] ; then
				echo "Found build log. Getting details"
				build_details=`tail --lines=13 $build_log`
				mail_text="Build details:"			
				mail_text="$mail_text"$'\n'************
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text $build_details"
				attachments=" -a  $build_report"
			fi
			if [ -f "$test_log" ] ; then
				echo "Found test log. Getting details"
				test_details=`tail --lines=12 $test_log`
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text Test details:"			
				mail_text="$mail_text"$'\n'************
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text $test_details" 
				attachments=" $attachments -a  $test_report"
			fi
			if [ -f "$test_log_her" ] ; then
				echo "Found HER test log. Getting details"
				test_details=`tail --lines=12 $test_log_her`
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text Test details:"			
				mail_text="$mail_text"$'\n'************
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text $test_details" 
				attachments=" $attachments -a  $test_report_her"
			fi
			if [ -f "$test_log_hes" ] ; then
				echo "Found HES test log. Getting details"
				test_details=`tail --lines=12 $test_log_hes`
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text Test details:"			
				mail_text="$mail_text"$'\n'************
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text $test_details" 
				attachments=" $attachments -a  $test_report_hes"
			fi
			if [ -f "$test_log_hey" ] ; then
				echo "Found HEY test log. Getting details"
				test_details=`tail --lines=12 $test_log_hey`
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text Test details:"			
				mail_text="$mail_text"$'\n'************
				mail_text="$mail_text"$'\n' 
				mail_text="$mail_text $test_details" 
				attachments=" $attachments -a  $test_report_hey"
			fi
			
			`echo "$mail_text" | mutt $attachments -s "$subject" $email` 	
			echo "Report email sent."
			break #for now only 1 arg supported
		fi		
	done
else
	echo "No arguments specified. Sending simple notification"
	subject="Notification from $hostname:$curUser at $starttime"
	mail_text="Notification sent from $hostname:$curUser at $starttime"
	mail_text="$mail_text"$'\n'
	mail_text="$mail_text Last 4 commands that were executed:"
	mail_text="$mail_text"$'\n'
	commands=`history 4`
	mail_text="$mail_text $commands"
	`echo "$mail_text" | mutt -s "$subject" $email` 
fi

 
