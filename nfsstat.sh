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
# nfsstat.sh
#
# invoke nfsstat before/after measurement period and create report
#
export LANG=C

NFSSTATOUT=nfsstat.int

if [ $# -ne 1 ]; then
 echo "nfsstat.sh: usage: nfsstat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

echo "\n     NFSSTAT: Collecting NFSSTAT statistics before the run...."
echo "\n\n\n                   N  F  S  S  T  A  T    O  U  T  P  U  T\n" > $NFSSTATOUT
echo "\n\nHostname:  "  `hostname -s` >> $NFSSTATOUT
echo "\n\nTime before run:  " `date` >> $NFSSTATOUT

echo "\f\n\n\n     N  F  S  S  T  A  T    O  U  T  P  U  T    B  E  F  O  R  E    R  U  N\n" > nfsstat.tmp
echo         "\n\nnfsstat -m" >> nfsstat.tmp
echo             "----------\n" >> nfsstat.tmp
nfsstat -m    >>nfsstat.tmp  2>&1
echo         "\n\nnfsstat -csnr" >> nfsstat.tmp
echo             "-------------\n" >> nfsstat.tmp
nfsstat -csnr >> nfsstat.tmp
echo "     NFSSTAT: Waiting specified time...."
trap 'kill -9 $!' 1 2 3 24
sleep $1 &
wait

echo "     NFSSTAT: Collecting NFSSTAT statistics after the run...."
echo "\n\nTime after run :  " `date` >> $NFSSTATOUT

# copy before data to out file now
/usr/bin/cat nfsstat.tmp >> $NFSSTATOUT
/usr/bin/rm nfsstat.tmp

echo "\f\n\n\n       N  F  S  S  T  A  T    O  U  T  P  U  T    A  F  T  E  R    R  U  N\n" >> $NFSSTATOUT
echo         "\n\nnfsstat -m" >> $NFSSTATOUT
echo             "----------\n" >> $NFSSTATOUT
nfsstat -m     >>$NFSSTATOUT  2>&1
echo         "\n\nnfsstat -csnr" >> $NFSSTATOUT
echo             "-------------\n" >> $NFSSTATOUT
nfsstat -csnr >> $NFSSTATOUT

echo "     NFSSTAT: Interval report is in file $NFSSTATOUT"
