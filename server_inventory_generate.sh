#!/bin/bash
# Author : Siddhartha Sinha
# Purpose: Generating Server Inventory csv file
#
nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'>/tmp/server_list
for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
do
ssh -q -o ConnectTimeout=3 $SERVER_NAME "uname -n |tr '\n' ',' && cat /proc/cpuinfo|grep -c processor |tr '\n' ',' && free -m|grep Mem|awk '{print \$2}' |tr '\n' ',' && fdisk -l 2>/dev/null |grep Disk|grep sd[abc]|sed -e 's/\,//g'|awk  '{print \$2\$3\$4}'|tr '\n' ','" >>/tmp/server-inventory.csv
echo "" >>/tmp/server-inventory.csv
done

