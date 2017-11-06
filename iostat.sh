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
# iostat.sh
#
# invoke iostat for specified interval and create interval and summary reports
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "iostat.sh: usage: iostat.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# exit if iostat executable is not installed
if [ ! -f /usr/bin/iostat ]; then
  echo "     IOSTAT: /usr/bin/iostat command is not installed"
  echo "     IOSTAT:   This command is part of the 'bos.acct' fileset."
  exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

# determine interval and count
if [ $1 -lt 601 ]; then
 INTERVAL=10
 let COUNT=$1/10
else
 INTERVAL=60
 let COUNT=$1/60
fi

# need count+1 intervals for IOSTAT
let COUNT=COUNT+1

echo "\n\n\n       I O S T A T    I N T E R V A L    O U T P U T   (iostat $INTERVAL $COUNT)\n" > iostat.int
echo "\n\n\n        I  O  S  T  A  T    S  U  M  M  A  R  Y    O  U  T  P  U  T\n\n\n" > iostat.sum
echo "\n\nHostname:  "  `hostname -s` >> iostat.int
echo "\n\nHostname:  "  `hostname -s` >> iostat.sum
echo "\n\nTime before run:  " `date` >> iostat.int
echo "\n\nTime before run:  " `date` >> iostat.sum

trap 'kill -9 $!' 1 2 3 24
echo "\n     IOSTAT: Starting I/O Statistics Collector [IOSTAT]...."
iostat  -R -a -T -D -l $INTERVAL $COUNT > iostat.Dl &
iostat $INTERVAL $COUNT > iostat.tmp &
iostat -A -Q $INTERVAL $COUNT > aiostat.int &

# wait required interval
echo "     IOSTAT: Waiting for measurement period to end...."
wait

#####
#cp iostat.tmp iostat.matt

# save time after run
echo "\n\nTime after run :  " `date` >> iostat.int
echo "\n\nTime after run :  " `date` >> iostat.sum

echo "     IOSTAT: Generating reports...."

# put awk script in temp file for later use
cat <<EOF > iostat.awk
BEGIN {
}

{
   if(\$1 == "tty:") { # next rec is tty data
      state = 1;
      ttyhdr = \$0; # save tty header
      ttycnt++;
      next;
   }

   if(\$1 == "Disks:") { # next rec is tty data
      state = 2;
      diskhdr = \$0; # save disk header
      diskcnt++;
      next;
   }

   if(state == 1) { # tty stuff
      stin    += \$1;
      stout   += \$2;
      suser   += \$3;
      ssys    += \$4;
      sidle   += \$5;
      siowait += \$6;
      state = 0;
      next;
   }

   if(state == 2) { # disk stuff
      if(NF > 0) { # while there are additional io entries
         disksum();
      }
      else {
         state = 0;
         nms = 0;
      }
      next;
   }
}

END {

   atin    = stin    / ttycnt;
   atout   = stout   / ttycnt;
   auser   = suser   / ttycnt;
   asys    = ssys    / ttycnt;
   aidle   = sidle   / ttycnt;
   aiowait = siowait / ttycnt;
   printf("\n");
   print ttyhdr;
   printf(" %12.1f %12.1f  %16.1f %8.1f  %9.1f %9.1f\n", \
      atin, atout, auser, asys, aidle, aiowait);

   print "\n" diskhdr;
   for(i = 1; i <= nms; i++) {
      name = nm[i];
      act = tmact[i]  / diskcnt;
      ps  = kbps[i]   / diskcnt;
      tp  = tps[i]    / diskcnt;
      rd  = kbread[i] / diskcnt;
      wr  = kbwrtn[i] / diskcnt;
      printf("%-13s  %5.1f  %8.1f  %8.1f  %16d %9d\n", \
         name, act, ps, tp, rd, wr);

   }
}

function disksum() {
   nms++;

   nm[nms]      = \$1;
   tmact[nms]  += \$2;
   kbps[nms]   += \$3;
   tps[nms]    += \$4;
   kbread[nms] += \$5;
   kbwrtn[nms] += \$6;
}
EOF

# get rid of first iostat report that shows stats since ipl
#B=$(iostat 1 1 | wc -l | cut -c1-9)
#let B="$B+1"
#/usr/bin/tail +`echo $B` iostat.tmp > iostat.tmp2
#/usr/bin/mv iostat.tmp2 iostat.tmp

echo "\n\n\n" >> iostat.int
/usr/bin/cat iostat.tmp >> iostat.int

# generate summary report
echo "\n\n\n" >> iostat.sum
#/usr/bin/awk -f iostat.awk iostat.tmp >> iostat.sum

/usr/bin/rm  iostat.awk iostat.tmp

echo "     IOSTAT: Interval report is in file iostat.int"
echo "     IOSTAT: Summary report is in file iostat.sum"
