#!/bin/bash

view_label=`ade pwv | grep "VIEW_LABEL" | awk '{print $3}'`
echo "View Label	:	$view_label"

latest_label=`ade showlabels -latest | grep "FUSIONAPPS"`
echo "Latest Label	: 	$latest_label"
echo ""


if [ "$view_label" = "$latest_label" ]; then
	echo "The view is on the latest label already. NOT refreshing"
else
	echo "Attempting to refresh to $latest_label"
	echo ""
	ade refreshview -label $latest_label
fi
echo ""
