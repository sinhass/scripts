#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: 27
#
# (C) COPYRIGHT International Business Machines Corp.  2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# emstat.sh
#
# invoke emstat before/during/after measurement period and generate reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "emstat.sh: usage: emstat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# exit if emstat executable is not installed
if [ ! -f /usr/bin/emstat ]; then
  echo "     EMSTAT: /usr/bin/emstat command is not installed"
  echo "     EMSTAT:   This command is part of the optional"
  echo "                'bos.perf.tools' fileset."
  exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

# determine INTERVAL and COUNT
if [ $1 -lt 601 ]; then
 INTERVAL=10
 let COUNT=$1/10
else
 INTERVAL=60
 let COUNT=$1/60
fi

# need count+1 intervals for VMSTAT
let COUNT=COUNT+1

echo "\n\n\n      E M S T A T    I N T E R V A L    O U T P U T   (emstat $INTERVAL $COUNT)\n" > emstat.int
echo "\n\nHostname:  "  `hostname -s` >> emstat.int
echo "\n\nTime before run:  " `date` >> emstat.int

echo "     EMSTAT: Starting Emulator Statistics Collector (emstat $INTERVAL $COUNT)"
trap 'kill -9 $!' 1 2 3 24
/usr/bin/emstat -a  $INTERVAL $COUNT > emstat.tmp &

# wait required interval
echo "     EMSTAT: Waiting for measurement period to end...."
wait

# save time after run
echo "\n\nTime after run :  " `date` >> emstat.int

echo "     EMSTAT: Generating reports...."

echo "\n\n\n" >> emstat.int
/usr/bin/cat emstat.tmp >> emstat.int

/usr/bin/rm  emstat.tmp

echo "     EMSTAT: Interval report is in file emstat.int"
