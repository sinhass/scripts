#!/bin/ksh
# This file is intended for checking firmware levels of RISC boxes for
# BCRS systems.
#
# Author: Nate Salazar, BCRS, Boulder, CO
# Email: natesala@us.ibm.com
##########################################################################

if [ -e firmware.txt ]
then
rm firmware.txt
fi

# Get Yes/No Function

GetYesNo()      {
        _ANSWER=
        if  [ $# -eq 0 ]; then
        echo "Usage: GetYesNo message" 1>&2
        exit 1
        fi

while :
do
        if [ "`echo -n`" = "-n" ]; then
                echo "$@\c"
                else
                        echo -n "$@"
        fi

        read _ANSWER
        case "$_ANSWER" in
                [yY] | yes | YES | Yes)         return 0 ;;
                [nN] | no  | NO  | No )         return 1 ;;
                * ) echo "Please Enter y or n."          ;;
        esac
tput clear
done
}

# Define email or not
if GetYesNo "Do you want an email sent with firmware information?[y/n]";
then
echo "Enter you email address: "
EMAIL=
read EMAIL
echo
else
EMAIL=""
echo
fi

# Here is all the microcode in the system
if GetYesNo "Do you want see all firmware in the system[y/n]?";
then
echo
echo "Here is all the microcode currently applied to the system:"
echo "----------------------------------------------------------"
echo
lsmcode -A
if [ -n "$EMAIL" ]
then
echo "Here is all the microcode currently applied to the system:" >> firmware.txt
echo "----------------------------------------------------------" >> firmware.txt
echo >> firmware.txt
lsmcode -A >> firmware.txt
echo >> firmware.txt
fi
else
echo
fi

# System's Firmware
echo
echo "Here is the system's firmware level: `lscfg -vp | grep -p Platform | grep alterable | cut -c 37-44`"
echo
echo

if [ -n "$EMAIL" ]
then
echo >> firmware.txt
echo "Here is the system's firmware level: `lscfg -vp | grep -p Platform | grep alterable | cut -c 37-44`" >> firmware.txt
echo >> firmware.txt
echo >> firmware.txt
fi

# Fiber Channel Adapters
echo "Here are the microcode levels for the HBAs in the system:"
echo
for i in `lsdev -Cc adapter | grep fcs | awk '{print $1}'`
do
echo "$i:" 
echo "\tModel:`lscfg -vpl $i | grep Model | awk '{print $2}'`"
echo "\tFirmware Level: `lscfg -vpl $i | grep Z9 | cut -c 39-48`"
done
echo

if [ -n "$EMAIL" ]
then
echo "Here are the microcode levels for the HBAs in the system:" >> firmware.txt

echo >> firmware.txt
for i in `lsdev -Cc adapter | grep fcs | awk '{print $1}'`
do
echo "$i:" >> firmware.txt
echo "\tModel:`lscfg -vpl $i | grep Model | awk '{print $2}'`" >> firmware.txt
echo "\tFirmware Level: `lscfg -vpl $i | grep Z9 | cut -c 39-48`" >> firmware.txt
done
echo >> firmware.txt
fi

# Ethernet Adapters
echo
echo "Here are the microcode levels for the network adapters that apply:"
echo
for i in `lsmcode -A | grep ent | cut -f 1 -d !`
do
echo "$i:"
echo "\tAdapter Type: `lsdev -l $i -F description`"
echo "\tFirmware Level: `lscfg -vpl $i | grep ROM | cut -c 37-42`"
done

if [ -n "$EMAIL" ]
then
echo >> firmware.txt
echo "Here are the microcode levels for the network adapters that apply:" >> firmware.txt
echo >> firmware.txt
for i in `lsmcode -A | grep ent | cut -f 1 -d !` 
do
echo "$i:" >> firmware.txt
echo "\tAdapter Type: `lsdev -l $i -F description`" >> firmware.txt
echo "\tFirmware Level: `lscfg -vpl $i | grep ROM | cut -c 37-42`" >> firmware.txt
done
fi

if [ -n "$EMAIL" ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put firmware.txt
quit
END_SCRIPT

rsh 172.21.64.2 -l docs mailx -s `hostname`_firmware $EMAIL < ./firmware.txt
rm firmware.txt
fi
