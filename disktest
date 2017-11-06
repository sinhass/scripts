#!/bin/ksh
# Very simple script to create a VG then export it and clear the PVID.
# Add more lines to make it do more...
logfile=/tmp/disktest.out
echo "Disk Testing Script" | tee $logfile 
echo "v1.0 Gary Raposo 10/02/01" | tee -a $logfile
echo "v2.0 Curtis Fields 02/19/03 add /tmp/disktest.out log" | tee -a $logfile
HOWMANY=`lspv | grep None | wc -l`
echo "This script will quickly test the"$HOWMANY" disks not currently in a VG."| tee -a $logfile
echo " "| tee -a $logfile
lspv | grep None | awk {'print $1'} | while read FREEDISK; do
echo "Making VG on $FREEDISK" | tee -a $logfile
mkvg -f -y $FREEDISK"vg" -s'128' '-n' $FREEDISK
echo "Varying off "$FREEDISK"vg" | tee -a $logfile
varyoffvg $FREEDISK"vg"
echo "Exporting "$FREEDISK"vg" | tee -a $logfile
exportvg $FREEDISK"vg"
echo "Clearing PVID on "$FREEDISK | tee -a $logfile
chdev -l $FREEDISK -a pv=clear
echo " " | tee -a $logfile
done
echo "All done!" | tee -a $logfile
