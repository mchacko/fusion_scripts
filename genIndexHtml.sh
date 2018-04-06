#! /bin/bash

# bct - Creates an index.html based on directory contents
# Author: Manish Chacko
# Created on: 21-Dec-2015
# Last updated: 21-Dec-2015

# Usage: bct.sh {bug number}

ROOT=/scratch/machack/public_html
HTTP="/"
OUTPUT="$1/site-index.html" 

i=0
echo "<UL>" > $OUTPUT
for filepath in `find "$ROOT" -maxdepth 1 -mindepth 1 -type d| sort`; do
  path=`basename "$filepath"`
  echo "$filepath"
  echo "  <LI>$path</LI>" >> $OUTPUT
  echo "  <UL>" >> $OUTPUT
  for i in `find "$filepath" -maxdepth 1 -mindepth 1 -type f| sort`; do
    file=`basename "$i"`
    echo "    <LI><a href=\"/$path/$file\">$file</a></LI>" >> $OUTPUT
  done
  echo "  </UL>" >> $OUTPUT
done
echo "</UL>" >> $OUTPUT
