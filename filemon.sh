#!/bin/ksh
# @(#)78        1.4     src/bos/usr/sbin/perf/pmr/filemon.sh, perfpmr, bos411, 9428A410j 4/14/94 10:08:01
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
# filemon.sh
#
# invoke RISC System/6000 filemon command and generate file system report
#
export LANG=C

show_usage()
{
	echo "Usage: filemon.sh [-T kbufsize] time"
 	echo "       time is total time in seconds to be traced."
	exit 1
}
do_timestamp()
{
        echo "`/bin/date +"%H:%M:%S-%D"` :\t$1"
}


if [ $# -lt 1 ]; then
	show_usage
fi

kbufsize=5242880
while getopts T: flag ; do
        case $flag in
                T)     kbufsize=$OPTARG;;
                \?)    show_usage
        esac
done
shift OPTIND-1
FTIME=$@

# exit if filemon executable is not installed
if [ ! -f /usr/bin/filemon ]; then
  echo "     FILEMON: /usr/bin/filemon command is not installed"
  echo "     FILEMON:   This command is part of the optional"
  echo "                'bos.perf.tools' fileset."
  exit 1
fi

echo "\n\n\n        F  I  L  E  M  O  N    O  U  T  P  U  T    R  E  P  O  R  T\n" > filemon.sum
echo "\n\nHostname:  "  `hostname -s` >> filemon.sum
echo "\n\nTime before run:  " `date` >> filemon.sum
echo "Duration of run:  $FTIME seconds"  >> filemon.sum

echo "\n     FILEMON: Starting filesystem monitor for $FTIME seconds...."
filemon -d -T $kbufsize -O all -uv >> filemon.sum
trap 'kill -9 $!' 1 2 3 24
do_timestamp "trcon initiated"
trcon
echo "     FILEMON: tracing started"
sleep $FTIME &
wait
do_timestamp "trcstop initiated"
nice --20 trcstop
echo "     FILEMON: tracing stopped"
do_timestamp "trcstop completed"

#echo "Time after run :  " `date` "\n\n\n" >> filemon.sum
echo "     FILEMON: Generating report...."

# wait until filemon has closed the output file
ps -fu root | grep ' filemon ' | grep -v grep > /dev/null
while [ $? = 0 ]; do
  sleep 5
  ps -fu root | grep ' filemon ' | grep -v grep > /dev/null
done

echo "\c     FILEMON: Report is in filemon.sum"
do_timestamp "filemon completed"
