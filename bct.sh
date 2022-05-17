#! /bin/ksh

#Must set 'bugTxt' and $bugNo variables before calling this proc.
updateBugDb()
{
	#if [[ $curUser -eq 0 ]];then
	#	echo "No User!"
	#	return
	#fi
        echo "Updating bug $bugNo."
	set +x

        sqlplus -s  /nolog <<-EOF
	connect $curUser/$password@"$connectStr"
        SET SERVEROUTPUT ON
        SET SCAN OFF
	SET FEEDBACK OFF
        DECLARE
        bugNumber rpthead.RPTNO%TYPE:=$bugNo;
        bugText VARCHAR2($MAXLEN):='$bugTxt';
        BugErrorCode Number;
        bugErrorMessage VARCHAR2(10000);
        BEGIN
        bug.bug_api.create_bug_text
        (p_rptno                  => bugNumber
        ,p_text                   => bugText
        ,p_line_type              => 'N'
        ,p_error_code              => BugErrorCode
        ,p_error_mesg              => bugErrorMessage
        ,p_hide                    =>'Y'
        );
        dbms_output.put_line('Return message for CREATE_BUG_TEXT: ' || bugErrorMessage);
        commit;
        END;
        /
	EOF
	if [[ $debug -eq 1 ]];then
       	 set -x
	fi


}

MAXLEN=32000
re='^[0-9]+$'
start_time=$(date +%s)
cfgFile=~/.Premerge.cfg
curUser=`whoami`

outfile=~/master_script_log.txt
#connectStr="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=amogridxp01-scan.us.oracle.com)(PORT = 1523))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME = bugap_adx.us.oracle.com)))"
connectStr='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=amogridxp09-scan.us.oracle.com)(PORT = 1529))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME = ldap_bugap.us.oracle.com)))'

 if [[ $1 = "" ]]; then
	echo "Bug number not specified, getting it from the transaction"
	bugNo=`ade describetrans -properties_only|grep "^ *BUG_NUM"|awk '{print $3}'`
	echo "Bug number found: $bugNo"
 elif [[ $1 =~ $re ]] ; then
	echo "Using bug number from argument: $1"
	bugNo=$1
 else
	echo "Bug number could not be determined. Exiting.."
	exit
fi

template=~/scripts/bct/bct_template.txt

#vim  $template
gedit $template
text=`cat $template`

 echo "$text"
 echo ""
 echo -n 'Continue with this bug closure text? (Y/n): '
 read cont
	if [ "$cont" = "N" ] || [ "$cont" = "n" ] ; then
		exit
	fi

echo "Current user: $curUser"
bugUid=$curUser
password=***REMOVED***
bugTxt=`cat $template`

updateBugDb

echo "Done. Exiting.."
