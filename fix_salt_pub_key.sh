#!/bin/bash
# Author: Siddhartha S Sinha
# V1.0
# Barefoot Networks
#nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur|egrep -v "bfmon01|pdu|ups|hydra" >/tmp/server_list
for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
do
echo $SERVER_NAME
ssh -q -o ConnectTimeout=2 $SERVER_NAME " sed -i -re 's/^master_finger: a1:0a:ae:1c:b1:f6:3d:14:1a:48:f2:fa:b8:25:2f:ec:6f:44:1e:57:ea:40:1a:5f:d0:ce:e4:96:bc:af:f1:11/\#master_finger:/' /etc/salt/minion && service salt-minion restart" 
done
