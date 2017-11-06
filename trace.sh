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
# trace.sh
#
#   Used to collect trace data and create reports from the collected data
#


show_usage()
{
 echo "trace.sh: usage: trace.sh [-j inhooks][-k exhooks][-L logsz][-T kbufsz][-S][-I][-i][-r][-l][-K][-g][-N][-C] [-n n][-s n] [-f file] [-A pids][-t tids] [-P[-P{p|t}] time"
 echo "     -S          enable lock tracing"
 echo "     -I          collect both lock trace and regular trace"
 echo "     -i          prompt user to start trace and stop trace"
 echo "     -j inhooks  comma-separated list of hooks to be included"
 echo "     -k exhooks  comma-separated list of hooks to be excluded"
 echo "     -L logsz    is total size of log buffer and disk space used"
 echo "     -T kbufsz   is total size of kernel buffer; defaults to logsz" 
 echo "     -r          runs post processing (trcrpt); -j and -k flags apply"
 echo "     -l          Loop continuously using circular trace buffer"
 echo "     -K          show delta time and not show hook ids in trcrpt"
 echo "     -g          do not run gennames"
 echo "     -N          do not collect inode table"
 echo "     -C          do not use log file per CPU option"
 echo "     -n number   run trace.sh <number> times in separate directories"
 echo "     -n 0        creates new dir and runs trace.sh in that dir"
 echo "     -s number   delay number second between each trace collection"
 echo "     -f file     stop trace when <file> exists"
 echo "     -A pids     comma-separated list of process id's to trace"
 echo "     -t tids     comma-separated list of thread id's to trace"
 echo "     -P p|t      specify propagation of process id's or thread id's"
 echo "     time        is total time in seconds to trace"
 exit 2
}

stop_othertraces()
{
  for i in 1 2 3 4 5 6 7; do
	/bin/trcstop -$i 2>/dev/null
  done
  /bin/trcstop 2>/dev/null
}



gen_otherfiles()
{
    # get inode output if needed (not present or older than .init.state)
    if [ ! -n "$noinodetbl" ]; then
      if [ ! -f trace.crash.inode -o trace.crash.inode -ot /etc/.init.state ]; then
	  if [ -f /usr/sbin/pstat ]; then
		/usr/sbin/pstat -i > trace.inode 2>/dev/null
		if [ $? != 0 ]; then
			echo "pstat failed"
		fi
	  fi
	  echo "inode" | /usr/sbin/kdb  >trace.crash.inode  2>&1  # in case pstat doesn't work
	  echo "i2" | /usr/sbin/kdb > trace.j2.inode 2>&1  # get JFS2 inode table
      fi
    fi
    # capture translation of major/minor to logical volume
    /usr/bin/ls -al /dev > trace.maj_min2lv

    # in case tprof is used to post process the trace files, get gensyms data
    /usr/bin/gensyms > trace.syms

    # get gennames output if needed (not present or older than .init.state)
    if [ -z "$nogennames" ]; then
      if [ ! -f gennames.out -o gennames.out -ot /etc/.init.state ]; then
        if [ "$GETGENNAMESF" = 1 ]; then
          echo "     TRACE.SH: Collecting gennames -f data"
          /usr/bin/gennames -f >gennames.out  2>&1
        else
          echo "     TRACE.SH: Collecting gennames data"
          /usr/bin/gennames >gennames.out  2>&1
        fi
      fi
    fi


    /bin/trcnm > $TNM
    echo "     TRACE.SH: Trcnm data is in file $TNM"

    /bin/cp /etc/trcfmt $TFMT
    echo "     TRACE.SH: /etc/trcfmt saved in file $TFMT"

    /usr/sbin/mount > $TRCMNT

}

link_trfiles()
{
  files=$@
  for file in $@; do
	if [ -f ../$file ]; then
		ln -s ../$file .
	fi
  done
}


gen_otherfilesN()
{
   if [ "$tcount" = 1 ]; then
	cd ..
	gen_otherfiles
	cd - >/dev/null
   fi
   link_trfiles trace.crash.inode gennames.out trace.syms trace.maj_min2lv trace.nm trace.fmt
}

do_trace()
{
   KERTYPE=`bootinfo -K`
   if [ "$KERTYPE" = 32 ]; then
	PURR=""
   else
      if  /usr/sbin/smtctl >/dev/null; then
	PURR="-p -r PURR"
      else
	PURR="-p"
      fi
   fi

  if [ "$1" = "getinstrumentedtrace" ]; then
        getlocktrace=1
  else
        getlocktrace=
  fi

  if [ ! -x /usr/bin/trace ]; then
	echo "\n     TRACE.SH: /usr/bin/trace command is not installed"
	echo   "     TRACE.SH:   This command is part of the optional"
	echo   "              bos.sysmgt.trace fileset"
	exit 1
  fi
  if [ -n "$excludehooks" ]; then
  	if lparstat -i | grep -i "Type.*Shared" >/dev/null; then
		exhooks="-k $excludehooks"
	else
		exhooks="-k 492,$excludehooks"
        fi
  fi
  if [ -n "$includehooks" ]; then
	inhooks="-j $includehooks"
  fi
  if [ -n "$loopflag" ]; then
  	ltype="-l"
  else
	ltype="-f"
  fi

  if [ -n "$ntraces" ]; then
	if [ -f $TCOUNTFILE ]; then
		read tcount < $TCOUNTFILE
		let tcount=tcount+1
	else
		tcount=1
	fi
	echo $tcount > $TCOUNTFILE
	mkdir trace$tcount
	cd trace$tcount
        echo "\n     TRACE.SH: Executing trace collection set $tcount"
  fi
  
  if [ -n "$locktracing" -o "$getlocktrace" = 1 ]; then
        echo "\n     TRACE.SH: Enabling locktrace"
	/usr/bin/locktrace -S
  else
	echo
  fi
  if [ -n "$interactive" ]; then
    echo "     TRACE.SH: Starting interactive trace"
  elif [ "$ltype" = "-l" ]; then
    echo "     TRACE.SH: Starting loop trace"
  else
    echo "     TRACE.SH: Starting trace for $time seconds"
  fi
  if [ "$ltype" = "-l" ]; then
		let LOGBUF=$KERNBUF*2
  fi
  if [ "$getlocktrace" = 1 ]; then
  echo "$trace $PROPAGATE $PROCESS_LIST $THREAD_LIST $PURR -j 106,10C,10E,112,113,134,139,465,46D,606,607,608,609 $ltype -n $CPUS -d -L $LOGBUF -T $KERNBUF -ao $TRAWL"
  $trace $PROPAGATE $PROCESS_LIST $THREAD_LIST $PURR -j 106,10C,10E,112,113,134,139,465,46D,606,607,608,609 $ltype -n $CPUS -d -L $LOGBUF -T $KERNBUF -ao $TRAWL
  else
  echo "$trace $PROPAGATE $PROCESS_LIST $THREAD_LIST $PURR $exhooks $inhooks $ltype -n $CPUS -d -L $LOGBUF -T $KERNBUF -ao $TRAW"
  $trace $PROPAGATE $PROCESS_LIST $THREAD_LIST $PURR $exhooks $inhooks $ltype -n $CPUS -d -L $LOGBUF -T $KERNBUF -ao $TRAW
  fi

  if [ -n "$interactive" ]; then
     echo "\nPress <enter> to START tracing \c"; /bin/line
  fi

  trcon		# start tracing

  echo "     TRACE.SH: Data collection started"
  if [ -n "$interactive" -o "$ltype" = "-l" ]; then
	if [ -n "$stop_trigger" ]; then
     		echo "\n     `/bin/date`"
		echo "\tWaiting for file <$stop_trigger_file> to exist ...\c"
		while :; do
			if [ -f "$stop_trigger_file" ]; then
				echo "\n\tFile <$stop_trigger_file> exists"
     				echo "     `/bin/date`"
				break;
			fi
			/usr/bin/sleep 1
		done
	else
     		echo "\nPress <enter> to STOP tracing ->\c"; /bin/line
	fi
  else
     /usr/bin/sleep $time
  fi

  echo "     TRACE.SH: Data collection stopped"
  /usr/bin/nice --20 trcstop
  echo "     TRACE.SH: Trace stopped"
  if [ -n "$locktracing" -o "$getlocktrace" = 1 ]; then
        echo "     TRACE.SH: Disabling locktrace"
	/usr/bin/locktrace -R
  fi

  if [ "$getlocktrace" != 1 ]; then
    if [ -n "$ntraces" ]; then
	gen_otherfilesN
	cd ..
    else
  	gen_otherfiles   # call function to collect trcnm, trcfmt, etc.
    fi
  fi

  # wait until trace has closed the output file
  /bin/ps -Nfu root | /bin/grep ' trace ' | /bin/grep -v grep > /dev/null
  while [ $? = 0 ]; do
    /bin/sleep 2
    /usr/bin/ps -Nfu root | /bin/grep ' trace ' | /bin/grep -v grep > /dev/null
  done
  if [ "$getlocktrace" = 1 ]; then
  	echo "     TRACE.SH: Binary trace data is in file $TRAWL"
  else
  	echo "     TRACE.SH: Binary trace data is in file $TRAW"
  fi
}

do_reports()
{
  if [ -n "$excludehooks" ]; then
	exhooks="-k $excludehooks"
  fi
  if [ -n "$includehooks" ]; then
	inhooks="-d $includehooks"
  fi
  # see if needed files are here
  if [ ! -f $TRAW ]; then
    if [ ! -f $TBIN ]; then
      echo "    TRACE.SH: $TRAW file not found..."
      exit 1
    fi
  else
    /usr/bin/trcrpt $CPUS -r $TRAW > $TBIN
    #rm ${TRAW}*
  fi
  if [ ! -f $TFMT ]; then
    echo "    TRACE.SH: $TFMT file not found..."
    exit 1
  fi
  if [ ! -f $TNM ]; then
    echo "    TRACE.SH: $TNM file not found..."
    exit 1
  fi

  echo "\n     TRACE.SH: Generating report...."
  msg="\n\n\n     T  R  A  C  E    I  N  T  E  R  V  A  L    O  U  T  P  U  T\n"
  echo $msg > $TRPT

  if [ -n "$Kflag" ]; then
    Ooptions="timestamp=0,exec=on,tid=on,cpuid=on,ids=0"
  else
    Ooptions="timestamp=1,exec=on,tid=on,cpuid=on"
  fi

  /usr/bin/trcrpt $exhooks $inhooks -t $TFMT -n $TNM -O $Ooptions $TBIN >> $TRPT

  echo "     TRACE.SH: Trace report is in file $TRPT"
}


############################## MAIN  ###########################33
LOGBUF=10000000
TRAW=trace.raw
TRAWL=trace.raw.lock
TBIN=trace.tr
TRPT=trace.int
TNM=trace.nm
TFMT=trace.fmt
TCOUNTFILE=tr.count
TRCMNT=trace.mount
trace=/bin/trace
CPUS="-C all"
unset rflag interactive includehooks excludehooks KERNBUF Kflag nogennames sleepdelay
unset EXTSHM
if [ "$GETGENNAMES" = 0 ]; then
	nogennames=1
fi

[ $# = 0 ] && show_usage
while getopts :t:A:P:CINn:s:griKlk:j:L:T:Sf: flag ; do
        case $flag in
		t)     THREAD_LIST="-t $OPTARG";;
		A)     PROCESS_LIST="-A $OPTARG";;
		P)     PROPAGATE="-P$OPTARG";;
		f)     stop_trigger=1;
		       stop_trigger_file=$OPTARG;;
                n)     ntraces=$OPTARG;;
                s)     sleepdelay=$OPTARG;;
		S)	locktracing=1;;
                I)      instrumentedtrace=1;;
		N)     noinodetbl=1;;
                C)     CPUS="";;
                g)     nogennames=1;;
                r)     rflag=1;;
                K)     Kflag=1;;
                l)     loopflag=1;;
                i)     interactive=1;;
                j)     includehooks=$OPTARG;;
                k)     excludehooks=$OPTARG;;
                L)     LOGBUF=$OPTARG;;
                T)     KERNBUF=$OPTARG;;
                \?)    show_usage
        esac
done
shift OPTIND-1
time=$@

if [ -z "$KERNBUF" ]; then   # if no -T, then set it equal to -L value
	KERNBUF=$LOGBUF
fi
if [ -z "$interactive" -a -z "$time" -a -z "$rflag" -a -z "$loopflag" ]; then  # no i flag or time specified
  echo "Must specify a time value in seconds or use the -i flag"
  show_usage
fi

if [ -n "$rflag" ]; then	# do post processing/generate reports
	if [ -n "$ntraces" ]; then
	   if [  "$ntraces" -gt 0 ]; then
             tcounter=0
	     while [ "$tcounter" -lt $ntraces ]; do
		let tcounter=tcounter+1
		cd trace$tcounter
  		echo "\n     TRACE.SH: Generating report for trace set $tcounter...."
		do_reports
		cd - >/dev/null
	     done
	   else
		read tcounter < $TCOUNTFILE
		cd trace$tcounter
  		echo "\n     TRACE.SH: Generating report for trace set $tcounter...."
		do_reports
		cd - >/dev/null
	   fi
	else
	   do_reports
	fi
else
	stop_othertraces 	# stop any sna traces etc currently running
	if [ -n "$ntraces" -a "$ntraces" -gt 0 ]; then
           tcounter=0
	   while [ "$tcounter" -lt $ntraces ]; do
		do_trace
		let tcounter=tcounter+1
		if [ -n "$sleepdelay" -a "$tcounter" -lt $ntraces ]; then
			echo "     TRACE.SH   sleeping for $sleepdelay seconds"
			sleep $sleepdelay
		fi
	   done
	else
		do_trace		
                if [ -n "$instrumentedtrace" ]; then
                        do_trace getinstrumentedtrace
                fi
	fi
fi
