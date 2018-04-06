#!/bin/bash

viewname="machack_v1main"
update_bug="Y"

if [ $1 = "" ]; then
	echo "No transaction name provided. Unable to continue"
	exit
fi

#check if the command is run from a view
 view="$(ade pwv)"
 if [ "$view" = "ade ERROR: Not in a view." ]; then
	echo "Not is a view. Will use view $viewname"
	ade useview $viewname
 else
	 currentview="$(ade pwv | grep 'VIEW_NAME' | awk '{print $3}')" 
	 if [ "$currentview" = "$viewname" ]; then
		echo "In build view already. Continuing.."
	else
		echo "Please run this command from the build view or from outside a view."
		exit
	fi
 fi

cd $HOME/view_storage/$ADE_VIEW_NAME
echo -n "Refreshing view..."
ade refreshview -latest > buildhed_refreshview.log
refreshview_out=""
refreshview_out=`cat buildhed_refreshview.log | grep "ade ERROR:"`
if [ -n $refreshview_out ]; then
	echo "Error during refreshview"
	echo "$refreshview_out"
	exit
fi
echo "Done."
exit

echo -n "Cleaning view..."
ade cleanview > buildhed_cleanview.log
cleanview_out=""
cleanview_out='cat buildhed_cleanview.log | grep "ade ERROR:"'
if [ -n $cleanview_out ]; then
	echo "Error during cleanview"
	echo "$cleanview_out"
	exit
fi
echo "Done."

echo "Repatching build home..."
jdev repatchBuildHome
echo "Done."

echo -n "Grabbing transaction $1..."
ade grabtrans $1  > buildhed_grabtrans.log
grabtrans_out=""
grabtrans_out='cat buildhed_grabtrans.log | grep "ade ERROR:"'
if [ -n $grabtrans_out ]; then
	echo "Error during grabtrans"
	echo "$grabtrans_out"
	exit
fi
echo "Done."

echo -n "Running build..."
cd $ADE_VIEW_ROOT/fusionapps/hed
ant clean build build-report | tee build-report.log > /dev/null
echo "Done."

if [ "$update_bug" = "Y" ]; then
	bugNo=`ade describetrans $1 -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
	echo "Bug number found: $bugNo"
	success=`tail --lines=13 build-report.log | grep "Status:" | awk '{print $3}'`
	re='^[0-9]+$'
	if [ "$bugNo" =~ $re ]; then # its a valid number
		if [ "$success" = "SUCCESS" ]; then  # the report shows a successful compile
			echo "Uploading reports to bugDB"
			bup $bugNo build-report.html build-report.log 
		else
			echo "Compile failed. Not uploading reports"
		fi
	else
		echo "Invalid bug number found. Unable to upload reports to bugDB"
	fi
else
	echo "Bug update turned off. Not updating bugDB"
fi

echo "Mailing the reports to machine owner.."
mailme reports
echo "Script completed. Exiting."


 
