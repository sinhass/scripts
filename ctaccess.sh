#!/usr/bin/env bash

CT_ACCESS () {
 AUTOUSER=ssinha
 HOST_NAME=$CT_MACHINE
 USER_NAME=$AUTOUSER
 FILE_NAME=/etc/ssh/sshd_config

  check_hostname() {
    nslookup $HOST_NAME 2>&1 >/dev/null
    if [ $? -ne 0 ];then
      echo "Please check the Server Name Again"
      exit 250
    fi
    getent passwd |grep $USER_NAME 2>&1 >/dev/null
    if [ $? -ne 0 ];then
      echo "Please check the User Name again."
      exit 251
    fi
  }

  add_users_now() {
    ssh -q $HOST_NAME -o ConnectTimeout=2 "cat $FILE_NAME |grep -w $USER_NAME" 2>&1 >/dev/null
    if [ $? -ne 0 ];then
      ssh -q $HOST_NAME -o ConnectTimeout=2 "perl -pi.bk -pe 's/AllowUsers.*\K/ $USER_NAME/;' $FILE_NAME && service sshd restart 2>&1 >/dev/null"
      if [ $? -eq 0 ];then
        echo "User name:$USER_NAME successfully addded to the Server:$HOST_NAME."
      else
        echo "Something is wrong please do it manually."
      fi
    else
      echo "User name:$USER_NAME already has access to $HOST_NAME Server."
    fi
  }


  echo "This script will add the user to ssh allow list to a specific server."
  check_hostname
  if [ $? -eq 0 ];then
    add_users_now
  fi
}
