#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: 27
#
# (C) COPYRIGHT International Business Machines Corp.  2000-2004
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# mpstat.sh
#
# invoke mpstat before/during/after measurement period and generate reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "mpstat.sh: usage: mpstat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# exit if mpstat executable is not installed
if [ ! -f /usr/bin/mpstat ]; then
  echo "     MPSTAT: /usr/bin/mpstat command is not installed"
  echo "     MPSTAT:   This command is part of the 'bos.acct' fileset."
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

# need count+1 intervals for MPSTAT
let COUNT=COUNT+1

echo "\n\n\n      M P S T A T    I N T E R V A L    O U T P U T   (mpstat $INTERVAL $COUNT)\n" > mpstat.int
echo "\n\nHostname:  "  `hostname -s` >> mpstat.int
echo "\n\nTime before run:  " `date` >> mpstat.int

echo "     MPSTAT: Starting mpstat Statistics Collector (mpstat $INTERVAL $COUNT)"
trap 'kill -9 $!' 1 2 3 24
/usr/bin/mpstat -a  $INTERVAL $COUNT > mpstat.tmp &

# wait required interval
echo "     MPSTAT: Waiting for measurement period to end...."
wait

# save time after run
echo "\n\nTime after run :  " `date` >> mpstat.int

echo "     MPSTAT: Generating reports...."

echo "\n\n\n" >> mpstat.int
/usr/bin/cat mpstat.tmp >> mpstat.int

/usr/bin/rm  mpstat.tmp

echo "     MPSTAT: Interval report is in file mpstat.int"
