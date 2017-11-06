#!/bin/bash
# Author: Siddhartha S Sinha
# V1.0
# Barefoot Networks
#nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur|egrep -v "bfmon01|pdu|ups|hydra" >/tmp/server_list
#for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
for SERVER_NAME in cs{10..27}
do
echo $SERVER_NAME
ssh -q $SERVER_NAME -o ConnectTimeout=2 "service salt-minion stop && perl -pi.bk -pe 's/10.201.202.245/bfsalt01.domain.com/;' /etc/salt/minion && sed -i -re 's/^#hash_type: sha256/hash_type: sha256/'  /etc/salt/master && rm -f /etc/salt/pki/minion/*  && service salt-minion restart 2>&1 >/dev/null"
done
