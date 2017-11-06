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
# tcpdump.sh
#
# invoke RISC System/6000 tcpdump command or generate report
#
export LANG=C
TCPDUMPOUT=tcpdump.raw
show_usage()
{
        echo "Usage: tcpdump.sh [-i] <seconds> | tcpdump.sh -r"
        echo "\t-i  name of interface ex. tr0 or en0 ..."
        echo "\t-r  produce report and place in $TCPDUMPOUT"
	echo "\ttime in seconds is how long to collect data"
        exit 1
}



if [ $# -eq 0 ]; then
	show_usage
fi

while getopts ri: flag ; do
        case $flag in
                i)     ifname="-i $OPTARG";;
                r)     doreport=1;;
                \?)    show_usage
        esac
done
shift OPTIND-1
sleeptime=$@

# see if tcpdump to be taken now
if [ -z "$doreport" ]; then
   # check if tcpdump executable is installed
   if [ ! -x /usr/sbin/tcpdump ]
   then
     echo "\n     TCPDUMP: /usr/sbin/tcpdump is not installed."
     echo   "     TCPDUMP:  This command is part of the optional"
     echo   "                 'bos.net.tcp.server' fileset."
     exit 1
   fi

   /usr/bin/rm -f $TCPDUMPOUT
   echo "\n     TCPDUMP: Starting tcpdump for $sleeptime seconds...."
   tcpdump ${ifname} -w $TCPDUMPOUT 2>/dev/null &
#  tcpdump -n > tcpdump.int &
   DUMP_PID=$!
   sleep $sleeptime
   kill -TERM $DUMP_PID
   echo "     TCPDUMP: tcpdump collected...."

   # wait until tcpdump has closed the output file
   ps -fu root | grep ' tcpdump ' | grep -v grep > /dev/null
   while [ $? = 0 ]
     do
       sleep 5
         ps -fu root | grep ' tcpdump ' | grep -v grep > /dev/null
           done

   echo "     TCPDUMP: Binary tcpdump data is in file $TCPDUMPOUT"
   exit 0
else

   # see if needed files are here
   if [ ! -f $TCPDUMPOUT ]
   then
     echo "    TCPDUMP: $TCPDUMPOUT file not found..."
     exit 1
   fi

   echo "\n     TCPDUMP: Generating report...."
   echo "\n\n\n  TCPDUMP  I N T E R V A L  O U T P U T   (tcpdump -vnr $TCPDUMPOUT)\n" > tcpdump.int
   tcpdump  -venr $TCPDUMPOUT >> tcpdump.int
fi
echo "     TCPDUMP: tcpdump report is in file tcpdump.int"
