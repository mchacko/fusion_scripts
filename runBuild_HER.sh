#!/bin/bash
cd $HOME/view_storage/$ADE_VIEW_NAME
ade refreshview -latest
ade cleanview
jdev repatchBuildHome
ade grabtrans $1
cd fusionapps/hed
ant clean build build-report | tee build-report.log
ant -Dtest.lrg=true -Dtest.project=HedHerCurriculumRegistryUiModelTest -Ddb.host=slcak358.us.oracle.com -Ddb.port=1563 -Ddb.sid=ems7642 -f build-recordsManagement.xml test test-report | tee test-report.log
