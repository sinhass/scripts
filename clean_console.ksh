#!/usr/bin/ksh
# Author : Siddhartha Sinha
# This script will clear the locked console screen and give a fresh
# login screen
#
echo "Enter the user name who locked the console:\c"
read _ANSWER
ps -aef|grep -i $_ANSWER|awk '{print $2}'|while read USER_NAME
do
kill -9 $USER_NAME
done
