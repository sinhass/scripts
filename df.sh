#!/bin/ksh
#-----------------------------------------------------------------------------
#  aix-storage  - package name - full Disk, VGs, LVs and  Filesystem Information
# -----------------------------------------------------------------------------
# @(#)$Id: df!,v 6.5 1998/03/18 22:42:20 kazik dev $$Name: $
# -----------------------------------------------------------------------------
# /u/bin/df! - script  - full  Disk and Filesystem Information , 03/22/95 JR
# df.sh - script  - full  Disk , VGs, LVs and  Filesystem Information , 2005.10.01
#         v.0.1 - 2005.10.01 - expanded output, addind datailed information 
#                 about disks  - Grzegorz Wypiór
#         v.0.3 - 2005.10.28 - change separator to "..." for compatybility with
#                 snap output
# -----------------------------------------------------------------------------
export LANG=en_US   
SEPAR1=".....\n.....   "
SEPAR2="\n....."
typeset -L79 SEPARLINE
if [[ -f $1 ]]
then
  ls -l $1
fi
if [[ -d $1 ]]
then
  ls -dl $1
fi
if [[ $# = 0  ]]
then
  DDIR=`date +%y%m%d.%H%M%S`
  RAPFL="df.$DDIR.txt"
  FILE=
else
  FILE=$1
  FS=`df $FILE | awk ' {print $7} ' | grep $FILE `
  if [[ -z $FS ]]
  then
    print "$1 - not a filesystem "
  fi
fi
print "$SEPAR1 uname -a $DDIR $FILE $SEPAR2"
uname -a

print "$SEPAR1 oslevel  $DDIR $FILE $SEPAR2"
oslevel

print "$SEPAR1 df -v $FILE $SEPAR2"
df -v $FILE

print "$SEPAR1 mount $FILE $SEPAR2"
mount 

print "$SEPAR1 lsfs -q $FILE $SEPAR2"
lsfs -q

if [[ -n $FILE ]]
then
  LVLIST=`df -v $FILE | awk ' {print $1} ' | grep -v Filesystem `
  for AA in $LVLIST
  do
    LV=` print $AA | grep dev | sed -e 's/\/dev\///g'`
    NETFS=` print $AA | grep ":" | sed -e 's/.*://g'`
    NETSYS=` print $AA | grep ":" | sed -e 's/:.*//g'`
    if [[ -n $NETFS ]]
    then
      print "====  rsh $NETSYS df -v $NETFS  ==============================="
      rsh $NETSYS df -v $NETFS
      NETLV=`rsh $NETSYS df -v $NETFS | grep $NETFS | awk ' {print $1} ' | \
        sed -e 's/\/dev\///g`
      print "====  rsh $NETSYS lslv -l $NETLV  ============================="
      rsh $NETSYS /etc/lslv -l $NETLV
      NETLISTPV=`rsh $NETSYS /etc/lslv -l $NETLV | grep hdisk | \
        awk ' {print $1} '`
      for NETPV in $NETLISTPV
      do
        print "====  rsh $NETSYS lspv $NETPV  =============================="
        rsh $NETSYS /etc/lspv $NETPV
      done
    else
      if [[ -n $LV ]]
      then
        print "====  lslv -l $LV  =========================================="
        lslv -l $LV
        PVLIST=`lslv -l $LV | grep hdisk | awk '{print $1}' `
        for PV in  $PVLIST
        do
          SEPARLINE="$SEPAR1 lspv -l $PV $SEPAR2"; print "$SEPARLINE"
          lspv -l  $PV
          SEPARLINE="$SEPAR1 lspv  $PV  $SEPAR2"; print "$SEPARLINE"
          lspv   $PV
          print
        done
      fi
    fi
  done
else
  PVLIST=`lspv | grep hdisk | awk '{print $1}' |sort`
  for PV in  $PVLIST
  do
    SEPARLINE="$SEPAR1 lspv -l $PV $SEPAR2"; print "$SEPARLINE"
    lspv -l  $PV
    SEPARLINE="$SEPAR1 lspv  $PV  $SEPAR2"; print "$SEPARLINE"
    lspv   $PV
    print
  done
  for PV in  $PVLIST
  do
    SEPARLINE="$SEPAR1 lscfg -pv -l $PV $SEPAR2"; print "$SEPARLINE"
    lscfg -pv -l  $PV
    print
  done
  PDLIST=`lsdev -C -c pdisk -s ssar|  awk '{print $1}' `
  for PD in  $PDLIST
  do
    SEPARLINE="$SEPAR1 lscfg -pv -l $PD #pd $SEPAR2"; print "$SEPARLINE"
    lscfg -pv -l  $PD
    print
  done
fi
  PDLIST=`lsvg | sort`
  for PD in  $PDLIST
  do
    SEPARLINE="$SEPAR1 lsvg -l $PD  $SEPAR2"; print "$SEPARLINE"
    lsvg -l  $PD
    print
    SEPARLINE="$SEPAR1 lsvg  $PD  $SEPAR2"; print "$SEPARLINE"
    lsvg   $PD
    print
  done
    SEPARLINE="$SEPAR1 ssaxlate -l $SEPAR2"; print "$SEPARLINE"
         for i in $(lsdev -CS1 -cpdisk -sssar -F name)                          
         do                                                                    
           echo "$i: "$(ssaxlate -l $i)                                       
         done
    SEPARLINE="$SEPAR1 saraid -l ssa0 -Iz  $SEPAR2"; print "$SEPARLINE"
ssaraid -l ssa0 -Iz
#-----------------------------------------------------------------------------
