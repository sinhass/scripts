#!/usr/bin/ksh
# This file intended to use for 2nd checking for BCRS Systems
# Author : Siddhartha S Sinha & Nate Salazar, BC&RS, Boulder,CO
# Email - sidsinha@us.ibm.com
# Courtesy : Bruce Blinn (Prentice Hall), and BCRS Starling Forest 
# for part of this script.
#
# We will define Pause Function Here. Before that let us setup the environment.
# We will disable the break/suspend signals also.
trap "" 2 3 9 24
#
# Here we will define Pause Function
#
Pause()
{
	echo ""
	echo "Hit Enter to clear the Screen and Continue........"
        read
tput clear
}
echo off
export TERM=vt100
tput clear
#
# Here we will define Yes/No Function.
#
GetYesNo()	{
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
		[yY] | yes | YES | Yes)		return 0 ;;
		[nN] | no  | NO  | No )		return 1 ;;
		* ) echo "Please Enter y or n."		 ;;
	esac
tput clear
done
}
#
#
#
#
#Network Information
POWER4docs()
{
MACHINE_INFO=`hostname`"\t"`uname -a | awk '{print $2}'`

for i in `lsdev -Cc adapter | grep ent | grep -v EtherChannel | awk '{print $1}'`
do
echo "`hostname` \t \t  $MACHINE_INFO\t`lscfg -vpl $i | egrep -i 'Specific|Hardware' | cut -c 37-50`\t `lscfg -vpl $i | grep Network | cut -c 37-49`\t$i" >> `hostname`_network.txt
done
for i in `lsdev -Cc adapter | grep fcs | awk '{print $1}'`
do
echo "`hostname` \t \t `lscfg -vpl $i | grep Z8 | cut -c 45-52`\t`lscfg -vpl $i | grep Physical | cut -c 24-36`\t$i" >> `hostname`_zones.txt
done

echo "Enter email address to send docs to:\c "
_EMAIL=
read _EMAIL
HOSTNAME=`hostname`

if [ -r `hostname`_network.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_network.txt
quit
END_SCRIPT

rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_network $_EMAIL < ./"$HOSTNAME"_network.txt
rm `hostname`_network.txt
fi
if [ -r `hostname`_zones.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_zones.txt
quit
END_SCRIPT
rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_zones $_EMAIL < ./"$HOSTNAME"_zones.txt
rm `hostname`_zones.txt
fi
}
#
#
#
#
#Network Information
POWER5docs()
{
MACHINE_INFO=`hostname`"\t"`uname -a | awk '{print $2}'`

for i in `lsdev -Cc adapter | grep ent | grep -v EtherChannel | awk '{print $1}'`
do
echo "$MACHINE_INFO\t`lscfg -vpl $i | egrep -i 'Specific|Hardware' | cut -c 47-60`\t`lscfg -vpl $i | grep Network | cut -c 37-49`\t$i" >> `hostname`_network.txt
done

for i in `lsdev -Cc adapter | grep fcs | awk '{print $1}'`
do
echo "`hostname` \t \t `lscfg -vpl $i | grep Z8 | cut -c 45-52`\t`lscfg -vpl $i | grep Physical | cut -c 34-47`\t$i" >> `hostname`_zones.txt
done

echo "Enter email address to send docs to:\c "
_EMAIL=
read _EMAIL
HOSTNAME=`hostname`

if [ -r `hostname`_network.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_network.txt
quit
END_SCRIPT

rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_network $_EMAIL < ./"$HOSTNAME"_network.txt
rm `hostname`_network.txt
fi
if [ -r `hostname`_zones.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_zones.txt
quit
END_SCRIPT
rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_zones $_EMAIL < ./"$HOSTNAME"_zones.txt
rm `hostname`_zones.txt
fi
}


# This is the main Program for 2nd checks.
#
echo "We will now verify this Systems Hardware Setup."
echo "        You can't quit this program midway. "
echo

# System Information
prtconf|egrep 'System Model|Number Of Processors|Processor Clock Speed|CPU Type|Good Memory Size'
echo
IDISK=`lsdev -Cc disk|egrep -ic 'SCSI Disk Drive'`
echo "Total nos of Internal/SCSI Disk = $IDISK"


# We will check the SCSI disks and their sizes
# This portion modified from STF Script.
# 
echo "And here are their Sizes"
for i in `lsdev -Cc disk |grep -i scsi|awk '{print $1}'`
do
disk=$i
DISKSZ=`bootinfo -s $disk`
if [[ -z $ALLDISKSZ ]]
then
ALLDISKSZ="$DISKSZ"
else
ALLDISKSZ="$ALLDISKSZ\n$DISKSZ"
fi
echo $disk is  $DISKSZ" MB"; 
done
echo ""
echo ""
Pause


#
# Here we will work with Fiber/SAN Disks
#
FCDISK=`lsdev -Cc disk|egrep -ic fc`
echo "Total nos of SAN/FIBER Disk = $FCDISK"
echo "And here are their Sizes"
for i in `lsdev -Cc disk |grep -i fcs|awk '{print $1}'`
do
fcdisk=$i
FCDISKSZ=`bootinfo -s $disk`
if [[ -z $FCALLDISKSZ ]]
then
FCALLDISKSZ="$FCDISKSZ"
else
FCALLDISKSZ="$FCALLDISKSZ\n$FCDISKSZ"
fi
echo $fcdisk is  $FCDISKSZ" MB"; 
done
Pause


#
# Now we will show the Summary of all the disk sizes.
#
echo "Here is the all available DISK Sizes Summary"

for i in `lsdev -Cc disk -F name`
do
disk=$i
DISKSZ_=`bootinfo -s $disk`
if [[ -z $ALLDISKSZ_ ]]
then
ALLDISKSZ_="$DISKSZ_"
else
ALLDISKSZ_="$ALLDISKSZ_\n$DISKSZ_"
fi
done
SIZES_=$(print $ALLDISKSZ_|sort -n|uniq)
print "\n\tTOTALS\n\t------\nQuantity\tSize (MB)\n--------\t---------"
for SIZE_ in $SIZES_
do NUM=$(print "$ALLDISKSZ_"|grep -c ^"$SIZE_"$)
   print "$NUM	   @	$SIZE_"
done
print "\n"
echo "You might see three times more Disk then actual. Because of dual path and"
echo "vpath. Please make sure either you see the exact amount or three times."
echo "For Single Path, exact amount and for dual path 3 times. Otherwise either"
echo "one path is not ok or SDD Drivers are not installed/loaded"
echo
Pause

# Tape Information
echo "Here are the Internal or SCSI Connected Tape Devices."
echo
lsdev -Cc tape|egrep -iv 'fc|smc'|awk '{print $1 "\t" $4" "$5" "$6" "$7"  "$8}'
echo
echo "Here is the CD/DVD Rom if any"
lsdev -Cc cdrom
echo
echo
FCTAPE=`lsdev -Cc tape|egrep -ic fc`
ROB=`lsdev -Cc tape|grep -ci smc`
echo "Total nos. of Robot/Autochanger = $ROB"
echo "Total nos of Fiber Connected Tape/Drive or Library Drives are $FCTAPE"
echo "And here are their list"
lsdev -Cc tape|egrep -i fc|awk '{print $1 "\t" $4" "$5" "$6" "$7"  "$8}'
Pause

# Network Adapter Information
GIGE=`lsdev -Cc adapter|egrep -c '10/100/1000'`
HFD=`lsdev -Cc adapter|egrep -x -c '10/100'`
FCS=`lsdev -Cc adapter|egrep -ici fcs`
echo "Currently this box has $FCS no(s) Fiber HBA"
echo "This box currently have $GIGE Gigabit Ethernet Card"
echo "And $HFD 100 Full Duplex Ethernet Card"
if GetYesNo "Do you want to test Network Connection[y/n] ?";
then 
echo "Now type the IP Address/Host name you want to Ping. You may start with NIMRod."
_IP=
read _IP
ping -c 4 $_IP
echo "Now you are done with all 2nd cheks. If you found any problem. Please fix it now."
echo
echo
echo
echo
echo
else 
echo
echo "Don't blame me if Ethernet doesn't work. You didn't test it."
echo 
fi

# Documentation Section
if GetYesNo "Do you want to create documentation[y/n]?";
then
MODEL=`lsconf | egrep -i 'Processor Type' | awk '{print $3}'`
if [ $MODEL == "PowerPC_POWER5" ]
then 
POWER5docs
else
POWER4docs
fi
else
echo
echo "If documentation does not yet exist, rerun this script and MAKE IT!!!"
echo

echo "Now Press any key to quit this program."
stty raw
ANYKEY=`dd bs=1 count=1 2>/dev/null`
stty -raw
tput clear
fi

