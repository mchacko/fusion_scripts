script_start_time=$(date +%s)

user=`whoami`
viewname=`date +"build%Y%m%d%H%M%S"`
update_bug="Y"
series_name="FUSIONAPPS_PT.V2MIBFPHGOLD_LINUX.X64"
#junit_db_mc="slcak358.us.oracle.com" 
#junit_port="1581" 
#junit_sid="ems2658"
junit_db_mc="slcak359.us.oracle.com" 
junit_port="1583" 
junit_sid="ems18261"
#junit_db_mc="slcak358.us.oracle.com" 
#junit_port="1586" 
#junit_sid="ems18163"
junit_full_suite="N"
run_test="Y"
start_time=`date`
curUser=`whoami`

getElapsedTime () 
{
task_elapsed_time=$(($task_end_time - $task_start_time))
secs=$((  task_elapsed_time % 60    ))  
mins=$((  ( task_elapsed_time / 60 ) % 60    ))  
hrs=$((  task_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`
}

echo "LRG  will be run on ade series $series_name"

# create a log directory for the build view
log_dir="/home/${curUser}/build_logs/${viewname}"
mkdir -p "$log_dir"

`echo "Script started processing at $start_time" > $log_dir/${1}.log`

#check if the command is run from a view
view="$(ade pwv)"
if [ "$view" != "ade ERROR: Not in a view." ]; then
	echo "Please run this command outside a view."
exit
fi

length="$#"
product_suite="hed"
repeat=1
re='^[0-9]+$'
if [  "$length" -gt 1 ]  ;then
	echo "Reading arguments.."
	index=2						
	for var in "$@"
	do 
		if [ "$var" =  "hed" ] ; then  
			product_suite="hed"
			echo "Based on argument provided to script, full HED test suite will be executed" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "her" ] ; then  
			product_suite="her"
			echo "Based on argument provided to script, full HER test suite will be executed" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "hes" ] ; then  
			product_suite="hes"
			echo "Based on argument provided to script, full HES test suite will be executed" | tee -a $log_dir/${1}.log
		elif [ "$var" =  "hey" ] ; then  
			product_suite="hey"
			echo "Based on argument provided to script, full HEY test suite will be executed" | tee -a $log_dir/${1}.log
                elif  [[ $var =~ $re ]]  ; then
			repeat=$var
			echo "Based on argument provided to script, test suite will be executed $repeat times" | tee -a $log_dir/${1}.log	
		fi		
	done
fi

cfgFile=~/.Premerge.cfg
curUser=`whoami`
email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
total_iterations="$repeat"

task_start_time=$(date +%s)
echo -n "Creating build view $viewname..." | tee -a $log_dir/${1}.log
`ade createview $viewname -series $series_name -latest > $log_dir/createview.log`
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

#`cp /home/machack/workaround/build-*.xml ~/view_storage/${curUser}_${viewname}/fusionapps/hed/ -fv`

while [ $repeat -gt 0 ]; do
	
	current_num=$((total_iterations - repeat + 1))
	# delete output files from previous runs
	if [ $current_num -gt 1 ]; then
		`rm ~/view_storage/${user}_${viewname}/fusionapps/hed/TEST*`
	fi

	echo -n "Running LRG in view $viewname..." | tee -a $log_dir/${1}.log
	if [ "$product_suite" =  "hed" ] ; then 
		echo -n "Running HED Junits..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build.xml test test-report &> $log_dir/test-report_${current_num}.log"`
		task_end_time=$(date +%s)
		getElapsedTime			
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
	elif [ "$product_suite" =  "her" ] ; then 
		echo -n "Running HER Junits..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-recordsManagement.xml test test-report &> $log_dir/test-report_${current_num}.log"`
		task_end_time=$(date +%s)
		getElapsedTime			
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
	elif [ "$product_suite" =  "hes" ] ; then 
		echo -n "Running HES Junits..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-financialsManagement.xml test test-report &> $log_dir/test-report_${current_num}.log"`
		task_end_time=$(date +%s)
		getElapsedTime			
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
	elif [ "$product_suite" =  "hey" ] ; then 
		echo -n "Running HEY Junits..." | tee -a $log_dir/${1}.log
		`ade useview $viewname -silent -exec "ant -Dtest.lrg=true -Ddb.host=$junit_db_mc -Ddb.port=$junit_port -Ddb.sid=$junit_sid -f hed/build-campusCommunity.xml test test-report &> $log_dir/test-report_${current_num}.log"`
		task_end_time=$(date +%s)
		getElapsedTime			
		echo "Done. Task completed in $elapsed_time_formatted" | tee -a $log_dir/${1}.log
	fi
	
	
	testresult=""
	echo "" | tee -a $log_dir/${1}.log
	echo "Test results $current_num/$total_iterations at $starttime:" | tee -a $log_dir/${1}.log
	echo "******************"
	testresult=`tail --lines=12 $log_dir/test-report_${current_num}.log`
	echo "$testresult" | tee -a $log_dir/${1}.log
	echo "" | tee -a $log_dir/${1}.log
	echo "" | tee -a $log_dir/${1}.log
	
	`cp ~/view_storage/${user}_${viewname}/fusionapps/hed/test-report.html  $log_dir/test-report_${current_num}.html` 
	starttime=$(date)
	
	mail_text=""
	subject="Test report $current_num/$total_iterations $starttime"
	mail_text="$mail_text Test Details"
	mail_text="$mail_text"$'\n'***************** 
	mail_text="$mail_text $testresult"
	attachments=" -a /home/${curUser}/build_logs/${viewname}/test-report_${current_num}.html"
	`echo "$mail_text" | mutt $email $attachments -s "$subject" $cc_mail` 
	
	

	#viewname=`date +"build%Y%m%d%H%M%S"`
	repeat=$((repeat - 1))
	
done

echo -n "Destroying build view $viewname..." | tee -a $log_dir/${1}.log
`ade destroyview $viewname  -no_ask > $log_dir/destroyview.log `
echo "Done." | tee -a $log_dir/${1}.log

script_end_time=$(date +%s)
script_elapsed_time=$(($script_end_time - $script_start_time))
secs=$((  script_elapsed_time % 60    ))  
mins=$((  ( script_elapsed_time / 60 ) % 60    ))  
hrs=$((  script_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`
