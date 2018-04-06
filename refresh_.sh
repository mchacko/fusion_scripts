#!/bin/bash

view_label=`ade pwv | grep "VIEW_LABEL" | awk '{print $3}'`
echo "View Label	:	$view_label"

latest_label=`ade showlabels -latest | grep "FUSIONAPPS"`
echo "Latest Label	: 	$latest_label"
echo ""


if [ "$view_label" = "$latest_label" ]; then
	echo "Not necessary"
else
	echo "Yes please"
fi
echo ""
