#!/bin/sh

#Quick Script that nicely shows the hdisk and its size

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
echo $disk" = " $DISKSZ" MB"; 
done
SIZES=$(print $ALLDISKSZ|sort -n|uniq)
print "\n\tTOTALS\n\t------\nQuantity\tSize (MB)\n--------\t---------"
for SIZE in $SIZES
do NUM=$(print "$ALLDISKSZ"|grep -c ^"$SIZE"$)
   print "$NUM	   @	$SIZE"
done
print "\n"
