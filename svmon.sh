#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: IBM
#
# (C) COPYRIGHT International Business Machines Corp. 2000
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# svmon.sh
#
show_usage()
{
	echo "Usage: svmon.sh [-o outputfile]"
	echo "default output file is svmon.out"
}

# exit if svmon executable is not installed
if [ ! -f /usr/bin/svmon ]; then
  echo "     SVMON: /usr/bin/svmon command is not installed"
  echo "     SVMON:   This command is part of the 'bos.perf.tools' fileset."
  exit 1
fi


while getopts o: flag ; do
        case $flag in
                o)     filename=$OPTARG;;
                \?)    show_usage
        esac
done
if [ -z "$filename" ]; then
	filename=svmon.out
fi

echo "Date/Time:   `date`" >> $filename
echo "\n" >> $filename
echo "svmon -G" >> $filename
echo "----------" >> $filename
svmon -G >> $filename
echo "svmon -Pnsm" >> $filename
echo "----------" >> $filename
#svmon -Pns | tee svmon.tmp >> $filename
svmon -Pnsm  >> $filename
#
# list the 'mmap mapped to sid'
#
#grep 'mmap mapped to sid' svmon.tmp |
#while read P1 P2 P3 P4 P5 P6 SID P7; do
#    echo "\n"	>> $filename
#    echo "svmon -S $SID"	>> $filename
#    echo "---------------"	>> $filename
#    svmon -S $SID	>> $filename
#done
svmon -lS > ${filename}.S
#/usr/bin/rm -f svmon.tmp
