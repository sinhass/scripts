#!/bin/bash
# Author : Siddhartha Sinha
# date :03/07/2014
# Cleanup VM after clone
#
# We will clean up the device file name here to keep it consistent
sed -e /eth0/d -e s/eth1/eth0/ 70-persistent-net.rules > tmp70-persistent-net.rules && mv tmp70-persistent-net.rules 70-persistent-net.rules
#
# Now I will collect the ne MAC address of the hardware and add it to actual file

NEW_HW_ADDR=`ifconfig -a |grep HW|awk '{print $NF}'`
sed -re "s/(HWADDR=)[^=]*$/\1$NEW_HW_ADDR/" /etc/sysconfig/network-scripts/ifcfg-eth0 >/etc/sysconfig/network-scripts/ifcfg-eth0.TEMP && \mv /etc/sysconfig/network-scripts/ifcfg-eth0.TEMP /etc/sysconfig/network-scripts/ifcfg-eth0                 
sed -re "s/(IPADDR=)[^=]*$/\1/" -e "s/(GATEWAY=)[^=]*$/\1/" /etc/sysconfig/network-scripts/ifcfg-eth0 >/etc/sysconfig/network-scripts/ifcfg-eth0.TEMP && \mv /etc/sysconfig/network-scripts/ifcfg-eth0.TEMP /etc/sysconfig/network-scripts/ifcfg-eth0
# echo "system-config-network" >>/etc/rc.local