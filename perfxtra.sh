#!/bin/ksh

run_xtra_stuff()
{
	{
	#$PERFPMRDIR/trace.sh -k 254,255,116,117,535,537,539,492  5
	#$PERFPMRDIR/trace.sh -I -k 254,255,116,117,535,537,539,492  5
	#tprof -E PM_CYC -skeuzl -x sleep 30
	#$PERFPMRDIR/filemon.sh 10
	return 0
	} 2>&1 | tee -a perfxtra.int
}

initsleep=${1:-0}
count=${2:-0}
sleeptime=${3:-0}
n=0
xdirname=perf_xtra

sleep $initsleep
while [ $n -lt $count ];  do
	dir=${xdirname}_${n}
	if [ ! -f $dir ]; then
		mkdir $dir
	fi
	cd $dir
	d=`date +%b%d_%Y_%H:%I:%S`
	echo "Perf xtra programs started at $d" |tee  perfxtra.int
	run_xtra_stuff
	cd ..
	let n=n+1
	sleep $sleeptime
done
