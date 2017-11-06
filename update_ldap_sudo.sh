#!/bin/bash
# Author : Siddhartha Sinha
# Purpose: Updating Sudo across all servers. This can be resued to update any software across all CentOS Servers.
#
#nmap -sn 10.201.202.0/23 |grep -B 1 "up"|grep report|awk '{print $5}'|sed -e '/^[0-9]/d'|sort -ur>/tmp/server_list
for SERVER_NAME in `cat /tmp/server_list|awk -F "." '{print $1}'`
do
ssh -q -o ConnectTimeout=2 $SERVER_NAME "grep -w yeti /etc/sudo-ldap.conf"
  if [ $? -ne 0 ]; then
    scp -rp -o ConnectTimeout=2 /root/scripts/TESTAREA/new_sudo_ldap.conf $SERVER_NAME:/tmp/
    ssh -q -o ConnectTimeout=2 $SERVER_NAME "cat /tmp/new_sudo_ldap.conf >>/etc/sudo-ldap.conf"
  fi
  ssh -q $SERVER_NAME -o ConnectTimeout=2 "grep -w sudoers /etc/nsswitch.conf" 
  if [ $? -ne 0 ]; then
  ssh -q $SERVER_NAME -o ConnectTimeout=2 "perl -pi.bk -pe 'print qq/sudoers:    ldap files\n/ if eof;' /etc/nsswitch.conf" >/dev/null 2>&1
  fi
done

