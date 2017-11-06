#!/bin/bash
# Author : Siddhartha Sinha
# Purpose: Updating Sudo across all servers. This can be resued to update any software across all CentOS Servers.
#
nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur>/tmp/server_list
for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
do
ssh -q -o ConnectTimeout=2 $SERVER_NAME "yum update sudo -y"
done
