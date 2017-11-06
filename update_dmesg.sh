#!/bin/bash
# Author : Siddhartha Sinha
# Purpose: Updating Kerner Message to keep track of NFS issues.
#
echo "Type the message you want to write to dmesg:"
read DMESG
#nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur|egrep -v "^fs|nessie|ups|pdu|hydra|backupfs1">/tmp/server_list
for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
do
ssh -q -o ConnectTimeout=2 $SERVER_NAME "echo $DMESG `date` |tee /dev/kmsg"
done
