#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: IBM
#
# (C) COPYRIGHT International Business Machines Corp. 2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# monitor.sh
#
# invoke system performance monitors and collect interval and summary reports
#

show_usage()
{
 echo  "monitor.sh: usage: monitor.sh [-e][-n] [-p] [-s] [-h][-I sec][-N count][-S sec] [-i] time"
 echo  "      -e used if no emstat or alstat desired."
 echo  "      -n used if no netstat or nfsstat desired."
 echo  "      -p used if no pprof desired."
 echo  "      -s used if no svmon desired."
 echo  "      -m used if no mpstat desired."
 echo  "      -l used if no lparstat desired."
 echo  "      -h used if no hpmstat desired."
 echo  "      -i used if no iomon desired."
 echo  "      -I <seconds> specifies initial sleep delay before perfxtra monitoring starts"
 echo  "      -N <count> specifies number of times to run perfxtra monitoring prgrams"
 echo  "      -S <seconds> specifies number of seconds in between each iteration of perfxtra programs"
 echo  "      time is total time in seconds to be measured."
 exit 1
}

function lsps_as
{
echo "Date/Time:  " `/usr/bin/date`
echo "\n"
echo "/usr/sbin/lsps -a"
echo "-------"
/usr/sbin/lsps -a

echo "\n\n"
echo "/usr/sbin/lsps -s"
echo "-------"
/usr/sbin/lsps -s
}


function vmstat_i
{
echo "Date/Time:  " `/usr/bin/date`
echo "\n"
echo "vmstat -i"
echo "---------"
/usr/bin/vmstat -i
}

function vmstat_v
{
echo "Date/Time:  " `/usr/bin/date`
echo "\n"
echo "vmstat -v"
echo "---------"
/usr/bin/vmstat -v  2>&1
}

do_fcstat()
{
if [ -f /usr/sbin/fcstat ]; then
        echo "\n\n------------ FCSTAT    ----------\n" 
        for f in `lsdev -Ccadapter|grep "^fcs"|awk '{print $1}'`; do
        echo "\n------------------------------------------------" 
                fcstat $f 
        done
fi
}

do_pile_out()
{
	echo "pile" | /usr/sbin/kdb
}
do_vmker_out()
{
	echo "vmker -psize" | /usr/sbin/kdb
}

#--------------------------------------------------------
# MAIN
#--------------------------------------------------------
PERFPMRDIR=`whence $0`
PERFPMRDIR=`/usr/bin/ls -l $PERFPMRDIR |/usr/bin/awk '{print $NF}'`
PERFPMRDIR=`/usr/bin/dirname $PERFPMRDIR`
export LANG=C

if [ $# -eq 0 ]; then
        show_usage
fi

EMSTAT=1
NET=1
PROF=1
SVMON=1
MPSTAT=1
LPARSTAT=1
HPMSTAT=1
IOMON=1
perfxtra_init=0
perfxtra_count=0
perfxtra_sleep=0
while getopts ihenpsmlI:N:S: flag ; do
        case $flag in
		i)     IOMON=0;;
		h)     HPMSTAT=0;;
                e)     EMSTAT=0;;
                n)     NET=0;;
                p)     PROF=0;;
                s)     SVMON=0;;
		m)     MPSTAT=0;;
		l)     LPARSTAT=0;;
		I)     perfxtra_init=$OPTARG;;
		N)     perfxtra_count=$OPTARG;;
		S)     perfxtra_sleep=$OPTARG;;
                \?)    show_usage
        esac
done
shift OPTIND-1
SLEEP=$@

# check total time specified for minimum amount of 60 seconds
if [ "$SLEEP" -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

if [ $SLEEP -lt 601 ]; then
 INTERVAL=10
 let COUNT=$1/10
else
 INTERVAL=60
 let COUNT=$1/60
fi

# need count+1 intervals for VMSTAT
let COUNT=COUNT+1



if [ $SVMON = 1 ]; then
  echo "\n     MONITOR: Capturing initial lsps, svmon, and vmstat data"
else
  echo "\n     MONITOR: Capturing initial lsps and vmstat data"
fi

# do pile at start
do_pile_out > pile.before
do_vmker_out > vmker.before

# pick up lsps output at start of interval
lsps_as > lsps.before

# pick up vmstat -i at start of interval
vmstat_i > vmstati.before

# pick up vmstat -v at start of interval
vmstat_v > vmstat_v.before

# pick up svmon output at start of interval
# skip if svmon executable is not installed
# or if -s flag was specified
if [ ! -f /usr/bin/svmon ]; then
  echo "     MONITOR: /usr/bin/svmon command is not installed"
  echo "     MONITOR: This command is part of 'bos.perf.tools' fileset."
else
  if [ $SVMON = 1 ]; then
    $PERFPMRDIR/svmon.sh -o svmon.before
  fi
fi


# pick up fcstat output at end of interval
do_fcstat > fcstat.before

echo "     MONITOR: Starting perf_xtra programs: initsleep=$perfxtra_init count=$perfxtra_count sleep=$perfxtra_sleep"
$PERFPMRDIR/perfxtra.sh $perfxtra_init $perfxtra_count  $perfxtra_sleep &
echo "     MONITOR: Starting system monitors for $SLEEP seconds."

# skip nfsstat and netstat if -n flag used
if [ "$NET" = 1 ]; then
 if [ -x /usr/sbin/nfsstat ]; then
  $PERFPMRDIR/nfsstat.sh $SLEEP > /dev/null &
 fi
 $PERFPMRDIR/netstat.sh $SLEEP > /dev/null &
fi

$PERFPMRDIR/ps.sh $SLEEP > /dev/null &

$PERFPMRDIR/vmstat.sh $SLEEP > /dev/null &

if [  "$EMSTAT" = 1 ]; then
	$PERFPMRDIR/emstat.sh $SLEEP > /dev/null &
fi

if [  "$MPSTAT" = 1 ]; then
	$PERFPMRDIR/mpstat.sh $SLEEP > /dev/null &
fi
if [  "$LPARSTAT" = 1 ]; then
	$PERFPMRDIR/lparstat.sh $SLEEP > /dev/null &
fi
if [  "$HPMSTAT" = 1 ]; then
	$PERFPMRDIR/hpmstat.sh $SLEEP > /dev/null &
fi

$PERFPMRDIR/sar.sh $SLEEP > /dev/null &

$PERFPMRDIR/iostat.sh $SLEEP > /dev/null &

#$PERFPMRDIR/aiostat.sh $SLEEP > /dev/null &

if [ "$IOMON" = 1 ]; then
	$PERFPMRDIR/iomon -i $INTERVAL -l $COUNT > iomon.out &
fi

if [ "$PROF" = 1 ]; then
  # Give some time for above processes to startup and stabilize
  /usr/bin/sleep 5
  $PERFPMRDIR/pprof.sh $SLEEP > /dev/null &
fi


# wait until all child processes finish
echo "     MONITOR: Waiting for measurement period to end...."
trap 'echo MONITOR: Stopping...but data collection continues.; exit 2' 1 2 3 24
/usr/bin/sleep $SLEEP &
wait

if [ "$SVMON" = 1 ]; then
  echo "\n     MONITOR: Capturing final lsps, svmon, and vmstat data"
else
  echo "\n     MONITOR: Capturing final lsps and vmstat data"
fi

# do pile at end
do_pile_out > pile.after
do_vmker_out > vmker.after

# pick up lsps output at end of interval
lsps_as > lsps.after

# pick up vmstat -i at end of interval
vmstat_i > vmstati.after

# pick up vmstat -v at end of interval
vmstat_v > vmstat_v.after

# pick up svmon output at end of interval
# skip if svmon executable is not installed
# or if -s flag was specified
if [ -f /usr/bin/svmon -a "$SVMON" = 1 ]; then
  $PERFPMRDIR/svmon.sh  -o svmon.after
fi

# pick up fcstat output at end of interval
do_fcstat > fcstat.after

echo "     MONITOR: Generating reports...."

# collect all reports into two grand reports

echo "Interval File for System + Application\n" > monitor.int
echo "Summary File for System + Application\n" > monitor.sum

/usr/bin/cat ps.int >> monitor.int
/usr/bin/cat ps.sum >> monitor.sum
/usr/bin/rm ps.int ps.sum

echo "\f" >> monitor.int
/usr/bin/cat sar.int >> monitor.int
echo "\f" >> monitor.sum
/usr/bin/cat sar.sum >> monitor.sum
/usr/bin/rm sar.int sar.sum

echo "\f" >> monitor.int
/usr/bin/cat iostat.int >> monitor.int
echo "\f" >> monitor.sum
/usr/bin/cat iostat.sum >> monitor.sum
/usr/bin/rm iostat.int iostat.sum

echo "\f" >> monitor.int
cat vmstat.int >> monitor.int
echo "\f" >> monitor.sum
/usr/bin/cat vmstat.sum >> monitor.sum
/usr/bin/rm vmstat.int vmstat.sum

echo "\nAIO data is in aiostat.int" >> monitor.int
#echo "\f" >> monitor.int
#/usr/bin/cat aiostat.int >> monitor.int 2>/dev/null
#/usr/bin/rm aiostat.int 2>/dev/null


if [ -n "$EMSTAT" ]; then
	echo "\f" >> monitor.int
	/usr/bin/cat emstat.int >> monitor.int
	/usr/bin/rm emstat.int
fi

# skip nfsstat and netstat if -n flag used
if [ $NET = 1 ]; then
 if [ -x /usr/sbin/nfsstat ]; then
  echo "     MONITOR: Network reports are in netstat.int and nfsstat.int"
 else
  echo "     MONITOR: Network report is in netstat.int"
 fi
fi

echo "     MONITOR: Monitor reports are in monitor.int and monitor.sum"
