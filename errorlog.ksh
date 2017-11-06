#! /bin/ksh
#
# $0 = errmon.sh
#
# Written 11/3/1998 Bill Verzal.
#
# This script will run every [interval] and check the error log
# for new entries.  Upon finding them, it will send an email to
# administrators containing a message indicating the change
# in errlog status, as well as the offending lines.
#
if [ "$1" = "-v" ] ; then
   set -x
fi
lc="NULL"
tc="$lc"
# lc="last count"
# tc="this count"
#interval=900
interval=300
# Divide interval by 60 to get number of minutes.
me="$0 - Hardware error monitoring"
myname=`hostname`
args="$*"
mailto="root"
#mailto="alert"
true=0
false=1
boj=`date`

echo "$me started.\nThis message goes to $mailto." | mail -s "Errlog monitoring for $myname" $mailto
logger "$0 started"

while [ "$true" != "$false" ] ; do
   tc=`errpt -dH,S,U,O | wc -l`
   if [ "$lc" = "NULL" ] ; then
      lc="$tc"
   fi
   if [ "$lc" -ne "$tc" ] ; then
      foo=`echo "$tc-$lc"|bc`
      msg="$foo new errors have been found on $myname"
      page_msg="$foo new errors have been found on $myname"
      errlogl=`errpt -dH,S,U,O -a`
      if [ "$tc" -eq "0" ] ; then
         msg="$msg\n Errlog was cleared"
      else
         logger $msg
         msg=" $msg \n Errlog details below:\n $errlogl \n"
         echo "$msg" | mail -s "Errlog status change on host $myname" $mailto
      fi
   fi
   lc="$tc"
   sleep $interval
done
