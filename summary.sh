#!/bin/sh

total_iterations=16
repeat=16


testresult=""
while [ $repeat -gt 0 ]; do
	current_num=$((total_iterations - repeat + 1))
	testresult1=`tail --lines=12 /home/machack/build_logs/build20160521110536_test-report_${current_num}.log`
	testresult="$testresult $testresult1"
	testresult="$testresult"$'\n' 
	testresult="$testresult"$'\n' 
	testresult="$testresult"$'\n' 
	repeat=$((repeat - 1))
done

echo $testresult > /home/machack/test_results.txt

`echo "$testresult" | mutt  manish.chacko@oracle.com -s "Test result summary"` 
