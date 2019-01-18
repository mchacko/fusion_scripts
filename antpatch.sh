#!/bin/bash

# antpatch - Build an ant pacth for the current transaction in the view
#
# Author: Manish Chacko
# Created on: 27-Jul-2016
# Last updated: 27-Jul-2016
# Version 0.1

script_start_time=$(date +%s)
logName=`date +"antpatch_log_%Y%m%d%H%M%S"`
start_time=`date`

getElapsedTime () 
{
task_elapsed_time=$(($task_end_time - $task_start_time))
secs=$((  task_elapsed_time % 60    ))  
mins=$((  ( task_elapsed_time / 60 ) % 60    ))  
hrs=$((  task_elapsed_time / 3600    ))
elapsed_time_formatted=`printf "%02d:%02d:%02d\n" $hrs $mins $secs`
}

echo "" | tee -a $logName.log
echo "***************************************************************************" | tee -a $logName.log
echo "*********************** Ant patch builder *********************************" | tee -a $logName.log
echo "" | tee -a $logName.log
echo "" | tee -a $logName.log


#check if the command is run from a view
view="$(ade pwv)"
if [ "$view" == "ade ERROR: Not in a view." ]; then
	echo "Please run this command inside a view with a saved transaction." | tee -a $logName.log
exit
fi

echo "Script started processing at $start_time" | tee -a $logName.log

bugNo=`ade describetrans $1 -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
if [ "$bugNo" = "" ]; then
	echo "Could not determine bug number from transaction. Exiting.." | tee -a $logName.log
	exit
else
	echo "Found bug number $bugNo"  | tee -a $logName.log
fi

transName=`ade describetrans | grep "^ *TRANSACTION" | awk '{print $2}'`
if [ "$transName" = "" ]; then
	echo "Could not determine transaction name from ADE. Exiting.." | tee -a $logName.log
	exit
else
	echo "Found transaction name $transName"  | tee -a $logName.log
fi

start_time=`date`
echo "Starting ant patch -- $start_time" | tee -a $logName.log

task_start_time=$(date +%s)
ant patch -DgraphFile=../build_metadata/graph.xml -Dtransaction=$transName -Dbug=$bugNo -Dbaseproductfamily=hed | tee -a $logName.log

task_end_time=$(date +%s)
getElapsedTime
echo "Done. Task completed in $elapsed_time_formatted"  | tee -a $logName.log

