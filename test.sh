#!/bin/bash
viewname="build20151127181419"


email="manish.chacko@oracle.com"
echo "${email: -11}"

exit

echo "Sending report to $user." | tee  ~/build_logs/${viewname}_${1}.log2
cfgFile=~/.Premerge.cfg
curUser=`whoami`

email=`grep -i "^EMail:$curUser:" $cfgFile 2>/dev/null |cut -d: -f3|grep -i "@oracle.com$"`
if [[ -n $email ]];then
	echo "Reading email id from $cfgFile"  | tee -a ~/build_logs/${viewname}_${1}.log2
	echo "Email ID: $email" | tee -a ~/build_logs/${viewname}_${1}.log2
	echo "Sending email.." | tee -a ~/build_logs/${viewname}_${1}.log2

	subject="Build report for $1"
	build_details=`tail --lines=13 ~/build_logs/${viewname}_useview.log`
	attachments="-a /home/${curUser}/build_logs/${1}_build-report.log   -a /home/${curUser}/build_logs/${1}_build-report.html"
	mail_text="Build details:"			
	mail_text="$mail_text"$'\n'************
	mail_text="$mail_text"$'\n' 
	mail_text="$mail_text $build_details"
 			
	`echo "$mail_text" | mutt $attachments -s "$subject" $email` 
else
	echo "Could not find user's email. Email notification cannot be sent" | tee -a ~/build_logs/${viewname}_${1}.log
fi
