#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: IBM
#
# (C) COPYRIGHT International Business Machines Corp.  2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# netstat.sh
#
# invoke netstat before/during/after measurement period and generate report
#
#set -x
export LANG=C

NETSTATOUT=netstat.int
show_usage()
{
        echo "Usage: netstat.sh <seconds> | netstat.sh -r"
        echo "\t-r  Resets all the statistics to 0"
        echo "\ttime in seconds is how long to collect data"
        exit 1
}

if [ $# -eq 0 ]; then
        show_usage
fi

while getopts r flag ; do
        case $flag in
                r)     doreset=1;RESETOPT="ZmZs";;
                \?)    show_usage
        esac
done
shift OPTIND-1
sleeptime=$@


# determine interval
if [ $sleeptime -lt 601 ]; then 
	INTERVAL=10 
else 
	INTERVAL=60
fi


# collect data before measurement interval
echo "\n     NETSTAT.SH: Collecting NETSTAT statistics before the run...."
echo "     N  E  T  W  O  R  K    P  E  R  F    D  A  T  A\n" > $NETSTATOUT
echo "Hostname:  "  `hostname -s` >> $NETSTATOUT
echo "Time before run:  " `date` >> $NETSTATOUT

echo "\n\n\n       N  E  T  W  O  R  K    B  E  F  O  R  E    R  U  N\n" >> $NETSTATOUT


# capture the adapter statistics
lsdev -C | grep Available |
    while read DEV garbage; do
        case "$DEV" in
          ent[0-9]*)
             if [ x != x$RESETOPT ]; then
               echo "\n\n\nentstat -r $DEV"
               echo       "---------------"
               entstat -r $DEV 2>&1
             else
               echo "\n\n\nentstat -d $DEV"
               echo       "---------------"
               entstat -d $DEV 2>&1
             fi
             ;;
          tok[0-9]*)
             if [ x != x$RESETOPT ]; then
               echo "\n\n\ntokstat -r $DEV"
               echo       "---------------"
               tokstat -r $DEV 2>&1
             else
               echo "\n\n\ntokstat -d $DEV"
               echo       "---------------"
               tokstat -d $DEV 2>&1
             fi
             ;;
          fddi[0-9]*)
             if [ x != x$RESETOPT ]; then
               echo "\n\n\nfddistat -r $DEV"
               echo       "---------------"
               fddistat -r $DEV 2>&1
             else
               echo "\n\n\nfddistat $DEV"
               echo       "--------------"
               fddistat $DEV 2>&1
             fi
             ;;
          atm[0-9]*)
             if [ x != x$RESETOPT ]; then
               echo "\n\n\natmstat -r $DEV"
               echo       "---------------"
               atmstat -r $DEV 2>&1
             else
               echo "\n\n\natmstat -d $DEV"
               echo       "---------------"
               atmstat -d $DEV  2>&1
             fi
             ;;
          css[0-9]*)
             echo "\n\n\n/usr/lpp/ssp/css/estat -d $DEV"
             echo       "------------------------------"
             if [ -f /usr/lpp/ssp/css/estat ]; then
                /usr/lpp/ssp/css/estat -d $DEV  2>&1
             else
                echo "/usr/lpp/ssp/css/estat NOT FOUND"
             fi
             ;;
          iba[0-9]*)
             echo "\n\n\n/usr/bin/ibstat -v $DEV"
             echo       "-----------------------"
             if [ -f /usr/bin/ibstat ]; then
                /usr/sbin/ibstat -v $DEV  2>&1
             else
                echo "/usr/sbin/ibstat NOT FOUND"
             fi
             ;;
          *)
             ;;
        esac
      done   >> $NETSTATOUT

for i in  in m rn rs s D an $RESETOPT; do
   echo "\n\n\nnetstat -$i" >> netstat.tmp
   echo       "------------" >> netstat.tmp
   netstat -$i >> netstat.tmp
done

netstat -ano > netstat.ano 2>/dev/null
echo "\n\n\nnetstat -ano" >> netstat.tmp
echo       "------------" >> netstat.tmp
cat netstat.ano >> netstat.tmp
/bin/rm -f netstat.ano
	

echo "\n\nnetstat -p arp" >> netstat.tmp
netstat -p arp >> netstat.tmp
echo "\n\n arp -a" >> netstat.tmp
arp -a >> netstat.tmp

# capture SP2 model 1 switch statistics
if [ -f /usr/lpp/ssp/css/vdidl2 ]; then
     echo "\n\n\nvdidl2 -i" >> netstat.tmp
     echo       "---------" >> netstat.tmp
     /usr/lpp/ssp/css/vdidl2 -i     >> netstat.tmp   2>&1
fi

# capture SP2 model 2 switch statistics
if [ -f /usr/lpp/ssp/css/vdidl3 ]; then
     echo "\n\n\nvdidl3 -i" >> netstat.tmp
     echo       "---------" >> netstat.tmp
     /usr/lpp/ssp/css/vdidl3 -i     >> netstat.tmp   2>&1
fi


# DLPI stats
echo "\n\n\nDLPI stats" >> netstat.tmp
netstat -P >> netstat.tmp 2>&1

# run netstat while command being executed
echo "\n\n\n    N E T S T A T   O U T P U T   D U R I N G   R U N  (netstat $INTERVAL)\n" > netstat.tmp1
trap 'kill -9 $!' 1 2 3 24
netstat $INTERVAL >> netstat.tmp1 &
NETSTAT=$!

echo "     NETSTAT.SH: Collecting $INTERVAL second intervals for $1 seconds."
sleep $1 &
wait $!
kill -9 $NETSTAT

# add before data to final file
/usr/bin/cat netstat.tmp >> $NETSTATOUT
/usr/bin/rm netstat.tmp

# add during data to final file
/usr/bin/sed -e "8d" netstat.tmp1 >> $NETSTATOUT
/usr/bin/rm netstat.tmp1

# collect data after measurement interval
echo "     NETSTAT.SH: Collecting NETSTAT statistics after the run...."

echo "\f\n\n\n\n       N  E  T  W  O  R  K    A  F  T  E  R    R  U  N\n" >> $NETSTATOUT
echo "\n\nTime after run :  " `date` >> $NETSTATOUT

# capture the adapter statistics
lsdev -C | grep Available |
    while read DEV garbage; do
        case "$DEV" in
          ent[0-9]*)
             echo "\n\n\nentstat -d $DEV"
             echo       "---------------"
             entstat -d $DEV 2>&1
             ;;
          tok[0-9]*)
             echo "\n\n\ntokstat -d $DEV"
             echo       "---------------"
             tokstat -d $DEV 2>&1
             ;;
          fddi[0-9]*)
             echo "\n\n\nfddistat $DEV"
             echo       "--------------"
             fddistat $DEV 2>&1
             ;;
          atm[0-9]*)
             echo "\n\n\natmstat -d $DEV"
             echo       "---------------"
             atmstat -d $DEV  2>&1
             ;;
          css[0-9]*)
             echo "\n\n\n/usr/lpp/ssp/css/estat -d $DEV"
             echo       "------------------------------"
             if [ -f /usr/lpp/ssp/css/estat ]
             then
                /usr/lpp/ssp/css/estat -d $DEV  2>&1
             else
                echo "/usr/lpp/ssp/css/estat NOT FOUND"
             fi
             ;;
          iba[0-9]*)
             echo "\n\n\n/usr/bin/ibstat -v $DEV"
             echo       "-----------------------"
             if [ -f /usr/bin/ibstat ]; then
                /usr/sbin/ibstat -v $DEV  2>&1
             else
                echo "/usr/sbin/ibstat NOT FOUND"
             fi
             ;;
          *)
             ;;
        esac
      done   >> $NETSTATOUT

# DLPI stats
echo "\n\n\nDLPI stats" >> $NETSTATOUT
netstat -P >> $NETSTATOUT 2>&1


# capture netstat settings
for i in  in m rn rs s D an ; do
   echo "\n\n\nnetstat -$i" >> $NETSTATOUT
   echo       "------------" >> $NETSTATOUT
   netstat -$i >> $NETSTATOUT
done

echo "\n\nnetstat -p arp" >> $NETSTATOUT
netstat -p arp >> $NETSTATOUT
echo "\n\n arp -a" >> $NETSTATOUT
arp -a >> $NETSTATOUT

# capture SP2 model 1 switch statistics
if [ -f /usr/lpp/ssp/css/vdidl2 ]; then
     echo "\n\n\nvdidl2 -i" >> $NETSTATOUT
     echo       "---------" >> $NETSTATOUT
     /usr/lpp/ssp/css/vdidl2 -i     >> $NETSTATOUT   2>&1
fi

# capture SP2 model 2 switch statistics
if [ -f /usr/lpp/ssp/css/vdidl3 ]; then
     echo "\n\n\nvdidl3 -i" >> $NETSTATOUT
     echo       "---------" >> $NETSTATOUT
     /usr/lpp/ssp/css/vdidl3 -i     >> $NETSTATOUT   2>&1
fi

echo "     NETSTAT.SH: Interval report is in file $NETSTATOUT"
