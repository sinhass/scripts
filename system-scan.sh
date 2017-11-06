#!/bin/ksh

###########################################################################
###########################################################################
### Function: disklist (hdisk listing)
### list the disks connected to system, with size next to it
###########################################################################
disklist() {
for disk in `lsdev -Cc disk -F name`; do
DISKSZ=`bootinfo -s $disk`
if [[ -z $ALLDISKSZ ]]; then
	ALLDISKSZ="$DISKSZ"
else
	ALLDISKSZ="$ALLDISKSZ\n$DISKSZ"
fi
CURDISK=`lsdev -Cc disk | grep -w $disk`

echo $CURDISK" ,  " $DISKSZ" MB"
done
SIZES=$(print $ALLDISKSZ|sort -n|uniq)
print "\n\tTOTALS\n\t------\nQuantity\tSize (MB)\n--------\t---------"
for SIZE in $SIZES
do NUM=$(print "$ALLDISKSZ"|grep -c ^"$SIZE"$)
   print "$NUM     @    $SIZE"
done

}
###########################################################################
###########################################################################
### Function: wwpnlist (WWPN listing)
### list the WWPNs of any Fiber-channel adapters, if any
###########################################################################
wwpnlist() {
for i in `lsdev -Cc adapter -F name | grep fcs`
do
WWID=`lscfg -vl $i | grep etwork | awk -F. "{print \\$14}"`
LOCCODE=`lsdev -C | grep $i | awk "{print \\$3}"`
echo "WWID for $i is $WWID at Location $LOCCODE"
done
}
###########################################################################
###########################################################################

###########################################################################
###########################################################################
### Function: tapelist (Tape listing)
### list the Tape Drives, if any
###########################################################################
tapelist() {
for i in `lsdev -Cc tape -F name| grep rmt` 
do
	RMT=`lsdev -Cc tape | grep $i`
	BLOCKSZ=`lsattr -El $i | grep block | awk '{print $2}'`
	printf "$RMT , Block Size = $BLOCKSZ"
	echo "<BR>"
done
}
###########################################################################
###########################################################################

###########################################################################
###########################################################################
### Function: scsilist (SCSI Adapter listing)
### list the SCSI Adapters, if any (most likely)
###########################################################################
scsilist() {
for i in `lsdev -Cc adapter -F name| grep scsi` 
do
	SCSI=`lsdev -Cc adapter | grep $i`
	printf "$SCSI"
	echo "<BR />"
done
}
###########################################################################
###########################################################################

###########################################################################
###########################################################################
### Function: niclist (NIC listing)
### list the Ethernet adapters, if any
###########################################################################
niclist() {
for i in `lsdev -Cc adapter -F name| grep ent` 
do
	ENT=`lsdev -Cc adapter | grep $i`
	printf "$ENT"
	echo "<BR />"
done

### Now give more detailed info about the config on each active adapter
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

}
###########################################################################
###########################################################################


HNAME=`hostname`
DATE=`date | awk '{print $1" "$2" "$3" "$6}'`

echo "<html>"
echo "<body>"

echo "<h2>System scan of $HNAME, executed on $DATE</h2>"
PROCS=`lsdev -Cc processor | wc -l`
echo "<h3>This machine has $PROCS processors, "

MEM=`lsattr -El mem0 | grep -w size | awk '{print $2}'`
echo "with $MEM MB of Memory</h3>"

### Call disklist - Show all hdisk drives attached to system
echo "<h4>Showing Disk Drives:"
echo "<pre>"
disklist
echo "</pre>"
echo "</h4>"

### Call tapelist - Show any tape drives attached
echo "<h4>Showing Tape Drives:"
echo "<pre>"
tapelist
echo "</pre>"
echo "</h4>"

### Call scsilist - Show SCSI adapters if any
echo "<h4>Showing SCSI Adapters attached to system:"
echo "<pre>"
scsilist
echo "</pre>"
echo "</h4>"

### Call wwpnlist - Show wwpn's if any
echo "<h4>Showing WWPN's of Fibre-Channel Adapters(if any):"
echo "<pre>"
wwpnlist
echo "</pre>"
echo "</h4>"

### Call niclist - show ethernet adapter information
echo "<h4>Showing Ethernet Adapters:"
echo "<pre>"
niclist
echo "</pre>"
echo "</h4>"

echo "</body>"
echo "</html>"
