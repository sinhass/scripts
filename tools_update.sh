#!/bin/bash
# Author : Siddhartha Sinha
# Purpose: Updating/installing  tools
#
nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur|egrep -v "ups|pdu">/tmp/server_list
    for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
       do
        echo "Running on $SERVER_NAME" 
        ssh -q -o ConnectTimeout=2 $SERVER_NAME "yum install iotop iftop -y" 2>&1 >/dev/null 
        if [ $? -ne 0 ];then
        echo "$SERVER_NAME update failed. Pls investigate" >>/root/scripts/TESTAREA/tools_update_fail.log
        fi 
	done

