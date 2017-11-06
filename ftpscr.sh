# This Script Copies all the drivers to the newly loaded box
# Author : Siddhartha S Sinha, sidsinha@us.ibm.com
#
mklv -y lv-utility -t jfs2 rootvg 128
crfs -v jfs2 -d lv-utility -m /utility -A yes -p rw -a agblocksize=4096
mount /utility
mkdir /utility/atape
mkdir /docs
mkdir /utility/tape_test_scripts
mkdir /utility/EMC_ODM
echo "y" >Y
/usr/samples/tcpip/anon.ftp<Y
chown -R ftp:staff /utility
chown -R ftp:staff /docs
ftp -n 172.21.64.2 <<!
quote user ftp
quote pass abcd@abcd.com
bin
cd /pub/utility
lcd /utility
prompt off
mget *
mget .profile.sid
cd /pub/utility/atape
lcd /utility/atape
mget *
cd /utility/tape_test_scripts
lcd /utility/tape_test_scripts
mget *
cd /pub/utility/EMC_ODM
lcd /utility/EMC_ODM
mget *
cd /pub/utility
lcd /etc
mget hosts
bye
!
chmod +x /utility/*
