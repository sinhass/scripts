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
# sar.sh
#
# invoke sar command for specified interval and create reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "sar.sh: usage: sar.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

# check if LPP installed
if [ ! -x /usr/sbin/sar ]; then
  echo "\n     SAR: /usr/sbin/sar command is not installed"
  echo   "     SAR:   This command is part of the optional"
  echo   "              bos.acct fileset"
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
let COUNT=COUNT+1

# put awk script in temp file for later use
/usr/bin/cat <<EOF > sar.awk
BEGIN {
   state = 0;
}

{
   if(state == 0) { # first record
      timestamp = \$1; # save timestamp
      state = 1;
   }

   if(\$1 == timestamp) { # header record
      printf ("\n");
      print \$0;
      if(\$2 == "proc-sz") { # no average this category - print next rcd
         state = 2;
      }
      next;
   }

   if(state == 2) { # first record after proc-sz header line
      print \$0;
      state = 1;
      next;
   }

   if(\$1 == "Average") { # summary line
      print \$0;
      state = 4;   # On MP machines, data is given for each cpu
      next;
   }

   if(state == 4) { # first record after Average summary line
      if( \$0 ~ /^$/ )  # next line is blank so return
         state = 1;
      else    # MP output has multiple lines, so print them
         print \$0;
      next;
   }

}

END {
}
EOF

echo "\n\n\n      S A R    I N T E R V A L    O U T P U T   (sadc $INTERVAL $COUNT; sar -A)\n" > sar.int
echo "\n\n\n        S  A  R    S  U  M  M  A  R  Y    O  U  T  P  U  T\n\n\n" > sar.sum
echo "\n\nHostname:  "  `hostname -s` >> sar.int
echo "\n\nHostname:  "  `hostname -s` >> sar.sum
echo "\n\nTime before run:  " `date` >> sar.int
echo "\n\nTime before run:  " `date` >> sar.sum

echo "\n     SAR: Starting System Activity Recorder [SAR]...."
trap 'kill -9 $!' 1 2 3 24
/usr/lib/sa/sadc  $INTERVAL $COUNT sar.tmp &

# wait required interval
echo "     SAR: Waiting for measurement period to end...."
wait

# save time after run
echo "\n\nTime after run :  " `date` >> sar.int
echo "\n\nTime after run :  " `date` >> sar.sum

echo "     SAR: Generating reports...."

# Generate ascii version of collected sar data
# For SMP machines list the cpu load by processor
NUM_CPU=`lsdev -C | grep proc | grep Available | wc -l`
if [ $NUM_CPU = 1 ]; then
    sar -Af sar.tmp > sar.tmp2
  else
    sar -A -P ALL -f sar.tmp > sar.tmp2
fi

# delete first 3 lines from this ascii file and overlay binary file
mv sar.tmp sar.bin
tail +5 sar.tmp2 > sar.tmp

# put interval data into output file
echo "\n\n\n" >> sar.int
/usr/bin/cat sar.tmp >> sar.int

# generate summary report
echo "\n\n" >> sar.sum
/usr/bin/awk -f sar.awk sar.tmp >> sar.sum

/usr/bin/rm  sar.awk sar.tmp sar.tmp2

echo "     SAR: Interval report is in file sar.int"
echo "     SAR: Summary report is in file sar.sum"
