#!/bin/bash

##########################################################
# Script to download a webpage using the 'wget' command  #
# Usage: ./webpagedl.sh <full webpage URL>               #
##########################################################

pagelink=$1
if [ -z "$pagelink" ]; then
    echo "usage: ./webpagedl.sh <full webpage URL>"
    exit 1
fi

mkdir -p webpages

filename=$(echo $pagelink | sed 's:/*$::' | sed 's#.*/##')
dldir="webpages/$filename.html"

wget -q -O "$dldir" "$pagelink"
get_exitcode=$?

if [ $get_exitcode -ne 0 ]; then
    echo "ERROR: webpagedl: the link '$pagelink' does not return a document (wget exit code $get_exitcode)" 1>&2
    exit 2
fi
echo "$dldir"
