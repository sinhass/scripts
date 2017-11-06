#!/bin/ksh

clear

for i in `ifconfig -a | grep flag | grep -v lo | awk -F: '{print $1}'`
do
	echo "Network Interface $i Information: "
	IP=`ifconfig $i | grep -v inet6 | grep inet | awk '{print $2}'`
	echo "$i's IP is $IP"
	NETMASK=`ifconfig $i | grep -v inet6 | grep inet | awk '{print $4}'`
	echo "$i's Netmask is $NETMASK"
	SELSPEED=`entstat -d $i | grep Speed | grep Selected | awk -F: '{print $2}'`
	RUNSPEED=`entstat -d $i | grep Speed | grep Running | awk -F: '{print $2}'`
	echo "Selected Media Speed for $i is $SELSPEED"
	echo "Running/Linked Media Speed for $i is $RUNSPEED"
	echo ""
done

mask="0xffffff00"

a=10
b=11
c=12
d=13
e=14
f=15







