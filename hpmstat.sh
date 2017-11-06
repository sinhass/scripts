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
# hpmstat.sh
#
# invoke hpmstat before/during/after measurement period and generate reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "hpmstat.sh: usage: hpmstat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# exit if hpmstat executable is not installed
if [ ! -f /usr/bin/hpmstat ]; then
  echo "     HPMSTAT: /usr/bin/hpmstat command is not installed"
  echo "     HPMSTAT:   This command is part of the 'bos.pmapi.tools' fileset."
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

echo "\n\n\n      H P M S T A T    I N T E R V A L    O U T P U T   (hpmstat $INTERVAL $COUNT)\n" > hpmstat.int
echo "\n\nHostname:  "  `hostname -s` >> hpmstat.int
echo "\n\nTime before run:  " `date` >> hpmstat.int

echo "     HPMSTAT: Starting Hardware Performance Monitor Statistics Collector (hpmstat -s 0 $INTERVAL $COUNT)"
trap 'kill -9 $!' 1 2 3 24
/usr/bin/hpmstat -s 0   $INTERVAL $COUNT > hpmstat.tmp &

# wait required interval
echo "     HPMSTAT: Waiting for measurement period to end...."
wait

# save time after run
echo "\n\nTime after run :  " `date` >> hpmstat.int

echo "     HPMSTAT: Generating reports...."

echo "\n\n\n" >> hpmstat.int
/usr/bin/cat hpmstat.tmp >> hpmstat.int

/usr/bin/rm  hpmstat.tmp

echo "     HPMSTAT: Interval report is in file hpmstat.int"
