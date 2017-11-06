#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: 27
#
# (C) COPYRIGHT International Business Machines Corp. 2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# iptrace.sh
#
# invoke RISC System/6000 iptrace command or generate report
#

export LANG=C

IPTRACEOUT=iptrace.raw
show_usage()
{
        echo "Usage: iptrace.sh <seconds> | iptrace.sh -r"
        echo "\t-r  produce report and place in $IPTRACEOUT"
        echo "\ttime in seconds is how long to collect data"
        exit 1
}

if [ $# -eq 0 ]; then
        show_usage
fi

while getopts r flag ; do
        case $flag in
                r)     doreport=1;;
                \?)    show_usage
        esac
done
shift OPTIND-1
sleeptime=$@

# see if iptrace to be taken now
if [ -z "$doreport" ]; then
   # check if iptrace executable is installed
   if [ ! -x /usr/sbin/iptrace ]; then
     echo "\n     IPTRACE: /usr/sbin/iptrace is not installed."
     echo   "     IPTRACE:  This command is part of the optional"
     echo   "                 'bos.net.tcp.server' fileset."
     exit 1
   fi

   echo "\n     IPTRACE: Starting iptrace for $1 seconds...."
   /usr/bin/rm -f $IPTRACEOUT
   startsrc -s iptrace -a `pwd`/$IPTRACEOUT
   sleep $sleeptime
   stopsrc -s iptrace
   echo "     IPTRACE: iptrace collected...."

   echo "     IPTRACE: Binary iptrace data is in file $IPTRACEOUT"
   sleep 2  # in case iptrace hasn't fully stopped
   exit 0
else

   # see if needed files are here
   if [ ! -f $IPTRACEOUT ]; then
     echo "    IPTRACE: $IPTRACEOUT file not found..."
     exit 1
   fi

   echo "\n     IPTRACE: Generating report...."
   echo "\n\n\n  I P T R A C E  I N T E R V A L  O U T P U T   (ipreport -rsn $IPTRACEOUT)\n" > iptrace.int
   ipreport -rsn $IPTRACEOUT >> iptrace.int
   echo "     IPTRACE: iptrace report is in file iptrace.int"
fi
