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
# tprof.sh
#
# invoke tprof to collect data for specified interval and again to produce report
#
export LANG=C

if [ $# -eq 0 ]; then
 echo "tprof.sh: usage: tprof.sh [-p program] time"
 echo "          time is total time to measure"
 echo "          -p program is optional executable to be profiled,"
 echo "          which, if specified, must reside in current directory"
 exit 1
fi

# exit if tprof executable is not installed
if [ ! -x /usr/bin/tprof ]; then
  echo "     TPROF: /usr/bin/tprof command is not installed"
  echo "     TPROF:   This command is part of the optional"
  echo "                'bos.perf.tools' fileset."
  exit 1
fi

# see if optional application program in current directory specified
case $1 in
  -p)  PGM=$2
       shift
       shift;;
   *)  PGM=tprof;;
esac

# collect raw data
do_purr()
{
if  /usr/sbin/smtctl >/dev/null 2>&1; then
        KERTYPE=`bootinfo -K`
        if [ "$KERTYPE" = 32 ]; then
                PURR=""
        else
                PURR="-R"
        fi
else
        PURR=""
fi
}

#PURR=""   # running with PURR again

echo "\n     TPROF: Starting tprof for $1 seconds...."
if id | grep root >/dev/null; then
	tprof $PURR -T 20000000 -l -r tprof -F -c -A all -x sleep $1 >tprof.out 2>&1
	echo "\n     TPROF: Starting tprof with no PURR for $1 seconds...."
	tprof -T 20000000 -l -r tprof_nopurr -F -c -A all -x sleep $1 >tprof_nopurr.out 2>&1
else
	tprof $PURR -l -r tprof -F -c -A all -x sleep $1 >tprof.out 2>&1
fi
echo "     TPROF: Sample data collected...."


# reduce data
echo "     TPROF: Generating reports in background (renice -n 20)"
PID=$$
renice -n 10 -p $PID

if [ $PGM = "tprof" ]
then
 tprof $PURR -l -r tprof -skeuj >> tprof.out 2>&1
 tprof  -l -r tprof_nopurr -zskeuj >> tprof_nopurr.out 2>&1
else
 tprof $PURR -l -p $PGM -r tprof -kseuj >> tprof.out 2>&1
fi

if [ -f tprof.prof ]; then
    mv tprof.prof tprof.sum
fi

echo "     TPROF: Tprof report is in tprof.sum"
