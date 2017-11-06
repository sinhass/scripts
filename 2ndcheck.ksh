#!/usr/bin/ksh
# This file intended to use for 2nd checking for BCRS Systems
# Author : Siddhartha S Sinha, BC&RS, Boulder,CO
# Email - sidsinha@us.ibm.com
# Courtesy : Bruce Blinn (Prentice Hall), and BCRS Starling Forest 
# for part of this script.
#
# We will define Pause Function Here. Before that let us setup the environment.
# We will disable the break/suspend signals also.
bold=`tput smso`
blink=`tput blink`
underline=`tput smul`
normal=`tput rmul`
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

# This is the main Program for 2nd checks.
#
echo "$bold We will now verify this Systems Hardware Setup."
echo "$bold        You can't quit this program midway. $normal"
echo
prtconf|egrep 'System Model|Number Of Processors|Processor Clock Speed|CPU Type|Good Memory Size'
echo
IDISK=`lsdev -Cc disk|egrep -ic 'SCSI Disk Drive'`
echo "$blink$underline Total nos of Internal/SCSI Disk = $IDISK$normal"
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
echo "$underline$blink Total nos of SAN/FIBER Disk = $FCDISK$normal"
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
echo "$blink$underline Here is the all available DISK Sizes Summary$normal"

for i in `lsdev -Cc disk -F name`
do
disk=$i
DISKSZ=`bootinfo -s $disk`
if [[ -z $ALLDISKSZ ]]
then
ALLDISKSZ="$DISKSZ"
else
ALLDISKSZ="$ALLDISKSZ\n$DISKSZ"
fi
done
SIZES=$(print $ALLDISKSZ|sort -n|uniq)
print "\n\tTOTALS\n\t------\nQuantity\tSize (MB)\n--------\t---------"
for SIZE in $SIZES
do NUM=$(print "$ALLDISKSZ"|grep -c ^"$SIZE"$)
   print "$NUM	   @	$SIZE"
done
print "\n"
echo "You might see three times more Disk then actual. Because of dual path and"
echo "vpath. Please make sure either you see the exact amount or three times."
echo "For Single Path, exact amount and for dual path 3 times. Otherwise either"
echo "one path is not ok or SDD Drivers are not installed/loaded"
echo
Pause
echo "$blink Here are the Internal or SCSI Connected Tape Devices$normal."
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
echo "$bold Now you are done with all 2nd cheks. If you found any problem. Please fix it now.$normal"
echo
echo
echo
echo
echo
else 
echo
echo "$blink$underline$bold Don't blame me if Ethernet doesn't work. You didn't test it.$normal"
echo 
echo "Now Press any key to quit this program."
stty raw
ANYKEY=`dd bs=1 count=1 2>/dev/null`
stty -raw
tput clear
fi
