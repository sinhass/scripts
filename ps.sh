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
# ps.sh
#
# invoke ps command before/after measurement period and create summary report
#
export LANG=C

if [ $# -ne 1 ]; then
 echo "ps.sh: usage: ps.sh time"
 echo "      time is total time in seconds to be measured."
 exit 1
fi

# check total time specified for minimum amount of 60 seconds
if [ $1 -lt 60 ]; then
 echo Minimum time interval required is 60 seconds
 exit 1
fi

# define function used twice later
psjoin()
{
# we have to do the following silly stuff because the ps -elk report was
# badly formatted in the GOLD build, and thus we have to awk it slightly
# differently.  The only difference is that the PID field starts one more
# character to the right.
#
# grep the build-level of bos.obj
#
BUILDLEVEL=`/usr/bin/lslpp -h -q bos.rte | grep COMPLETE | /bin/awk 'NR==1 {print $1}'`
#
# extract the revision and ptf identifiers
#
REV=`echo $BUILDLEVEL | /bin/awk 'FS="." {print $2}'`
PTF=`echo $BUILDLEVEL | /bin/awk 'FS="." {print $3}'`
#
# compare revision and ptf identifiers with supported build-levels
#
if [ "$REV" = "01" -a "$PTF" = "0000" ]; then
 # first, we pick out the fields that we want from the ps -elk output.
 # the values are piped directly into sort and subsequently stored in
 # the file "ps.elk.sort"
 ps -elk | awk \
 '
 # we note the position of the start of the PID field
 $4 == "PID" { pidstart = index($0, "UID") + 4;
               }
 $4 != "PID" && NF > 11 { $0 = substr($0, pidstart);
                          print $1, $3, $4, $5, $(NF-1), $NF
                        }
 ' | /usr/bin/sort > ps.elk.sort
else
 # first, we pick out the fields that we want from the ps -elk output.
 # the values are piped directly into sort and subsequently stored in
 # the file "ps.elk.sort"
 ps -elk | awk \
 '
 # we note the position of the start of the PID field
 $4 == "PID" { pidstart = index($0, "UID") + 3;
             }
 $4 != "PID" && NF > 11 { $0 = substr($0, pidstart);
                          print $1, $3, $4, $5, $(NF-1), $NF
                        }
 ' | /usr/bin/sort > ps.elk.sort
fi


# next, we pick out the fields that we want from the ps gv output.
# the values are piped directly into sort and subsequently stored
# in the file "ps.gv.sort"
ps gv | awk \
'
$1 != "PID" && NF > 9 { pid = $1;
                         print pid, $5, $6, $7, $10, $11, $7-$10
                       }
' | /usr/bin/sort > ps.gv.sort

# join the two sorted sets of ps values, sort in ascending PID order,
# and format for human readability
join ps.gv.sort ps.elk.sort | sort -n | awk \
'
BEGIN { printf "%5s %5s %5s %5s %5s %5s %3s %3s %3s %4s %7s %-8s\n",
        "PID", "PGIN", "SIZE", "RSS", "TRS", "DRS", "C", "PRI",
        "NI", "%CPU", "TIME", "CMD"
      }
{ printf "%5s %5s %5s %5s %5s %5s %3s %3s %3s %4s %7s %-8s\n",
           $1, $2, $3, $4, $5, $7, $8, $9, $10,$6,$11,$12
}
' > ps.join

# remove temporary files
/usr/bin/rm ps.elk.sort ps.gv.sort
}

echo "\n     PS: Collecting Active Processes before run ...."
echo "\n\n\n        P  S   I  N  T  E  R  V  A  L    O  U  T  P  U  T   (ps -efk)\n" > ps.int
echo "\n\n\n          P  S   S  U  M  M  A  R  Y    O  U  T  P  U  T   (ps -efk)\n\n\n" > ps.sum
echo "\n\nHostname:  "  `hostname -s` >> ps.int
echo "\n\nHostname:  "  `hostname -s` >> ps.sum
echo "\n\nTime before run:  " `date` >> ps.int
echo "\n\nTime before run:  " `date` >> ps.sum

psjoin
/usr/bin/mv ps.join psb.tmp

# collect extra file
echo "\n\nTime before run:  " `date` > psb.elfk
ps -elfk >> psb.elfk
ps -ekmo THREAD > psemo.before

echo "     PS: Waiting specified time period...."
trap 'kill -9 $!' 1 2 3 24
sleep $1 &
wait

echo "     PS: Collecting Active Processes after run ...."
# save time after run - assumes psb.sh has previously been run to create
# ps.int and ps.sum files
echo "\n\nTime after run :  " `date` >> ps.int
echo "\n\nTime after run :  " `date` >> ps.sum

psjoin
/usr/bin/mv ps.join psa.tmp

# extra file with different flags
echo "\n\nTime after run :  " `date` > psa.elfk
ps -elfk >> psa.elfk
ps -ekmo THREAD > psemo.after

echo "\n\n\n        Active Processes Before Run\n\n" >> ps.int
/usr/bin/cat psb.tmp >> ps.int
echo "\n\n\n        Active Processes After Run\n\n" >> ps.int
/usr/bin/cat psa.tmp >> ps.int

# first, we pick out the fields that we want from the "before" report.
# the header is discarded, along with values for PRI, NI, and %CPU.
# the remaining values are piped directly into sort and subsequently stored
# in the file "psb.sort"
/usr/bin/awk \
'
/PID/ { }
! /PID/ { print $1, $2, $3, $4, $5, $6, $7, $8, $11, $12
        }
' psb.tmp | sort > psb.sort

# next, we pick out the fields that we want from the "after" output.
# the header is discarded, along with values for USER, PRI, NI, %CPU,
# and CMD.  The remaining values are piped directly into sort and
# subsequently stored in the file "psa.sort"
/usr/bin/awk \
'
/PID/ { }
! /PID/ { print $1, $2, $3, $4, $5, $6, $7, $11
        }
' psa.tmp | sort > psa.sort

# join the two sorted sets of ps values and sort in ascending PID order
/usr/bin/join psb.sort psa.sort | sort -n > ps.join.sort

# concatenate the header onto the values and format for human readability
/usr/bin/cat ps.join.sort | awk \
'
BEGIN { printf "%5s %5s %5s %5s %5s %5s %5s %8s %8s %-8s\n",
        " ", "DELTA", "DELTA", "DELTA", "DELTA", "DELTA", "DELTA",
        "BEFORE", "AFTER", " ";
        printf "%5s %5s %5s %5s %5s %5s %5s %8s %8s %-8s\n",
        "PID", "PGIN", "SIZE", "RSS", "TRS", "DRS", "C",
        "TIME", "TIME", "CMD"
      }
{ printf "%5s %5s %5s %5s %5s %5s %5s %8s %8s %-8s\n",
         $1, $11-$2, $12-$3, $13-$4, $14-$5, $15-$6, $16-$7, $9, $17, $10
}
' > ps.delta

# generate summary report
echo "\n\n\n" >> ps.sum
/usr/bin/cat ps.delta >> ps.sum

# remove temporary files
/usr/bin/rm psb.tmp psa.tmp psb.sort psa.sort ps.join.sort ps.delta

echo "     PS: Regular report is in file ps.int"
echo "     PS: Delta report is in file ps.sum"

