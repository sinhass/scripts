#!/bin/bash
# Find the disk usage and send email
# - Sid
#

HOSTNAME=$(hostname -s)


COLLECT_DISK_USAGE () {
echo "List of top five users of $HOSTNAME:/local folder." >/tmp/$HOSTNAME-local.txt
echo "*******************************************" >>/tmp/$HOSTNAME-local.txt
du -hsx /local/* |sort -rh |head -5 >>/tmp/$HOSTNAME-local.txt
echo "******************************" >>/tmp/$HOSTNAME-local.txt
echo "List of top five users of $HOSTNAME:/local/tmp folder" >>/tmp/$HOSTNAME-local.txt
echo "*******************************************" >>/tmp/$HOSTNAME-local.txt
du -hsx /local/tmp/* |sort -rh |head -5 >>/tmp/$HOSTNAME-local.txt

}

GET_UID_SEND_EMAIL () {

cat /tmp/$HOSTNAME-local.txt |  grep local | awk -F '/' '{print $NF}' |sort -u |egrep -v "tmp|local " >/tmp/$HOSTNAME-local-userlist.txt

for USER_NAME  in `cat /tmp/$HOSTNAME-local-userlist.txt`
  do
    ldapsearch -x -b "dc=barefoot-int,dc=com" "uid=$USER_NAME" mail|grep ^mail|awk '{print $2}' >>/tmp/$HOSTNAME-local-email.txt
  done

for EMAIL_ID in `cat /tmp/$HOSTNAME-local-email.txt`
  do
    cat /tmp/$HOSTNAME-local.txt | mailx -s "$HOSTNAME:/local usage." $EMAIL_ID
  done

}

COLLECT_DISK_USAGE
GET_UID_SEND_EMAIL
