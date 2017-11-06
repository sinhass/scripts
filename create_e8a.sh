#!/usr/bin/ksh
# Author : Siddhartha Sinha
# Rev    : 1.0
# Date   : 08/29/2009
#
# This script will create & define all the NIM Clients from the /etc/hosts file
#
cat /etc/hosts|grep e8a | grep -v hmc |awk '{print $1" "$2}'|while read X Y
do
nim -o define -t standalone -a platform=chrp -a netboot_kernel=mp -a if1="find_net $Y 0" -a comments=$X $Y
done
