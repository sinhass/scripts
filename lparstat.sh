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
# lparstat.sh
#
# invoke lparstat before/during measurement period and generate reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "lparstat.sh: usage: lparstat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# exit if lparstat executable is not installed
if [ ! -f /usr/bin/lparstat ]; then
  echo "     LPARSTAT: /usr/bin/lparstat command is not installed"
  echo "     LPARSTAT:   This command is part of the 'bos.acct' fileset."
  exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit -1
fi

# determine INTERVAL and COUNT
if [ $1 -lt 601 ]; then
 INTERVAL=10
 let COUNT=$1/10
else
 INTERVAL=60
 let COUNT=$1/60
fi

# need count+1 intervals for LPARSTAT
let COUNT=COUNT+1

echo "\n\n\n       L P A R S T A T    I N T E R V A L    O U T P U T   (lparstat $INTERVAL $COUNT)\n" > lparstat.int
echo "\n\n\n        L P A R  S  T  A  T    S  U  M  M  A  R  Y    O  U  T  P  U  T\n\n\n" > lparstat.sum
echo "\n\nHostname:    `hostname -s`" >> lparstat.int
echo "\n\nHostname:    `hostname -s`" >> lparstat.sum
echo "\n\nTime before run:   `date` ">> lparstat.int
echo "\n\nTime before run:   `date` ">> lparstat.sum

echo "\n     LPARSTAT: Saving LPARSTAT -i statistics ...."
lparstat -i >> lparstat.sum

echo "     LPARSTAT: Starting Logical Partition Statistics Collector [LPARSTAT]...."
trap 'kill -9 $!' 1 2 3 24
#lparstat -H $INTERVAL $COUNT > lparstat.H &	 # performance overhead, so taken out now
lparstat -h $INTERVAL $COUNT > lparstat.h &
lparstat -l $INTERVAL $COUNT > lparstat.l &

# wait required interval
echo "     LPARSTAT: Waiting for measurement period to end...."
wait

# save time after run
echo "\n\nTime after run :   `date`" >> lparstat.int
echo "     LPARSTAT: Saving LPARSTAT statistics after run...."

#echo "\n\nlparstat -H" >> lparstat.int
#/usr/bin/cat lparstat.H >> lparstat.int
echo "\n\nlparstat -h" >> lparstat.int
/usr/bin/cat lparstat.h >> lparstat.int

#/usr/bin/rm  lparstat.H
/usr/bin/rm  lparstat.h

echo "     LPARSTAT: Interval report is in file lparstat.int"
echo "     LPARSTAT: configuration report is in file lparstat.sum"
