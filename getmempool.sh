#!/bin/ksh

do_bcd()
{
	echo "ib=16\n$1"|/usr/bin/bc
}
do_bch()
{
	echo "ob=16\n$1"|/usr/bin/bc
}


get_kdb()
{
#np=`vmstat -v|grep "memory pools"|awk '{print $1}'`
np=`echo "mempool *"| kdb |grep vmmdseg|wc -l`
nf=`echo "frameset *"|kdb | grep vmmdseg|wc -l`
let fr_per_pool=nf/np
p=0
f=0
str=""
while [ $p -lt $np ]; do
    if [ $fr_per_pool = 2 ]; then
	let f1=p*2
	let f2=f1+1
	pH=`do_bch $p`
	f1H=`do_bch $f1`
	f2H=`do_bch $f2`
	str="$str mempool $pH\nframeset $f1H\nframeset $f2H\n"
    elif [ $fr_per_pool = 4 ]; then
	let f1=p*4
	let f2=f1+1
	let f3=f2+1
	let f4=f3+1
	pH=`do_bch $p`
	f1H=`do_bch $f1`
	f2H=`do_bch $f2`
	f3H=`do_bch $f3`
	f4H=`do_bch $f4`
	str="$str mempool $pH\nframeset $f1H\nframeset $f2H\nframeset $f3H\nframeset $f4H\n"
    fi
    let p=p+1
done
echo $str | kdb
}

post_process()
{
file=$1
	
egrep -w "Page Size|(lrumem)|(nolru)|(all_lrumem)|Memory Pool|nb_frame|numclient|numperm|rpgcnt|Frame Set|numfrb" $file| while read line 
 do
	if echo $line | grep "Page Size" >/dev/null; then
		echo "  $line"
		continue
	fi
	hval=`echo "$line"|awk -F: '{print $2}'`
	nm=`echo "$line"|awk -F: '{print $1}'`
	if [ "$hval" != "" ]; then
		echo "\t$nm : `do_bcd $hval`"
	else
		if echo "$nm" | grep "Frame Set" >/dev/null; then
			echo "  $nm"
		else
			echo "\n$nm"
			
		fi
	fi
done
}


get_kdb > mempools.out

# get actual frames in each pool
str=""
egrep  "(lrumem)|(nolru)|(all_lrumem)" mempools.out | awk -F: '{print $2}'|while read lrumem 
do
	str="$str vmint $lrumem\n" 
done
i=0;set -A lrumemA `echo $str| kdb | grep pages|awk '{print $1}'`
str=""
while read line; do
	if echo $line | egrep "lrumem" >/dev/null; then
		echo $line | read a b c d e f
		echo "$a $b $c $d     $e ${lrumemA[$i]}"
	  	let i=i+1
	else
	  echo $line
	fi
done < mempools.out > mempools.out1
cp mempools.out mempools.save
		

mv mempools.out1 mempools.out
post_process mempools.out
echo "memp *\n\nvmpool -l *" | kdb
