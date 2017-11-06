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
# pprof.sh
#
#   Used to collect trace data and create reports for pprof
#


show_usage()
{
        echo "Usage: pprof.sh.sh [-L <logbuf size in bytes>] <time> | pprof.sh -r"
	echo "\t-L   size of trace log buffer in bytes"
        echo "\t-r   request pprof reports be produced"
        echo "\ttime is total time in seconds to trace"
 	echo "          trace log size is size of memory buffer in bytes"
 	echo "            (default is 4097152 bytes) "
        exit 1
}

if [ $# -eq 0 ]; then
        show_usage
fi

LOG=4097152
while getopts rL: flag ; do
        case $flag in
		L)     LOG=$OPTARG;;
                r)     doreport=1;;
                \?)    show_usage
        esac
done
shift OPTIND-1
sleeptime=$@

# see if trace to be taken now
if [ -z "$doreport" ]; then
  #
  # data collection
  #
  if [ ! -x /usr/bin/trace ]; then
    echo "\n     PPROF.SH: /usr/bin/trace command is not installed"
    echo   "     PPROF.SH:   This command is part of the optional"
    echo   "              bos.sysmgt.trace fileset"
    exit 1
  fi
  echo "\n     PPROF.SH: Starting trace for $sleeptime seconds"
  trace -d -L $LOG -T $LOG -afo pprof.trace.raw -j 001,002,003,005,006,135,106,10C,134,139,465,467,00A

  trcon
  echo "     PPROF.SH: Data collection started"
  sleep $sleeptime
  echo "     PPROF.SH: Data collection stopped"
  nice --20 trcstop
  echo "     PPROF.SH: Trace stopped"

  # wait until trace has closed the output file
  ps -fu root | grep ' trace ' | grep -v grep > /dev/null
  while [ $? = 0 ]; do
    sleep 1
    ps -fu root | grep ' trace ' | grep -v grep > /dev/null
    done
  echo "     PPROF.SH: Binary trace data is in file pprof.trace.raw"

  exit 0
fi

#
# data reduction
#
if [ -f pprof.trace.raw ]; then
  echo "    PPROF.SH: pprof.trace.raw file being converted to pprof.tr"
  trcrpt -r pprof.trace.raw > pprof.tr
fi

echo "\n     PPROF.SH: Generating pprof reports with:  pprof -I pprof.tr"
pprof -i pprof.tr
##end of shell##
