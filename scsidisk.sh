#!/bin/sh

#Quick Script that nicely shows the hdisk and its size

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
echo $disk" = " $DISKSZ" MB"; 
done
