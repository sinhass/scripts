#!/bin/ksh


collect_data()
{
svmon -Ss > $svskfile
vmstat -v > $vmstatvfile
svmon -G > $svgfile
svmon -S > $svsfile
svmon -Pn > $svpfile
svmon -Sl > $svslfile   #MATT
}

pg2MB()    { pgs=$1; echo "scale=2;$pgs*4096/1024/1024"|/usr/bin/bc -l; }

prnt()
{
unset pages
value="$2"
value_type="$3"
if [ "$value_type" = P ]; then
	pages=$value
elif [ "$value_type" = B ]; then
	let pages=$value/4096
elif [ "$value_type" = L ]; then
	let pages=$value*4096
elif [ "$value_type" = S ]; then
	let pages=$value*4194304
fi
if [ -z "$pages" ]; then 
	printf "%-51s | %8s | %10s \n" "$1" "$2" "$3"
else
	printf "%-51s | %8d | %10.2f \n" "$1" $pages `pg2MB $pages`
fi
}



do_total()
{
tot_mem_pgs=`grep memory $svgfile | awk '{print $2}'`
tot_inuse_pgs=`grep memory $svgfile | awk '{print $3}'`
free_pgs=`grep memory $svgfile | awk '{print $4}'`
grep "^L" $svgfile |awk '{print $4,$5}'|read poolsz poolfr
if [ -n "$poolsz" -a -n "$poolfr" ]; then
	lgpg_pool_fr=$((poolsz-poolfr))
	lgpg_pool_fr_4Kpgs=$((lgpg_pool_fr*4096))
else
	lgpg_pool_fr=0
	lgpg_pool_fr_4Kpgs=0
fi
unset poolsz poolfr
grep "^S" $svgfile |awk '{print $4,$5}'|read poolsz poolfr
if [ -n "$poolsz" -a -n "$poolfr" ]; then
	hgpg_pool_fr=$((poolsz-poolfr))
	hgpg_pool_fr_4Kpgs=$((hgpg_pool_fr*4194304))
else
	hgpg_pool_fr=0
	hgpg_pool_fr_4Kpgs=0
fi
echo "====================================================|==========|==========="
#printf "%51s | %7s | %10s\n" "DESCRIPTION" "Pages" "Megabytes"
prnt "Memory Overview" "Pages" "Megabytes"
echo "----------------------------------------------------|----------|-----------"
prnt "Total memory in system" $tot_mem_pgs P
prnt "    Total memory in use"  $tot_inuse_pgs P 
if [ "$lgpg_pool_fr" != 0 ]; then
	prnt "    Large Pages (16MB pages) unused" $lgpg_pool_fr L
fi
if [ "$hgpg_pool_fr" != 0 ]; then
	prnt "    Huge Pages (16GB pages) unused" $hgpg_pool_fr S
fi
prnt "    Free memory"  $free_pgs P
echo "====================================================|==========|==========="
}

do_total_acct()
{
#echo "----------------------------------------------------|---------|-----------"
total_acct=$((mem_wo_vmm_segids_dec+free_pgs+total_svmon_sids_pgs))
total_acct_inuse=$((mem_wo_vmm_segids_dec+total_svmon_sids_pgs))
#prnt "Total in system" $total_acct  P
#prnt "Total in-use" $total_acct_inuse  P
}

#light weight memory trace
do_lmt_mem()
{
lightweight_trace_mem_hex=`echo mtrc | kdb | grep mt_total_memory | awk '{print $2}'`
lightweight_trace_mem_bytes=`echo "ibase=16;$lightweight_trace_mem_hex" | bc`
lmt_pgs=$((lightweight_trace_mem_bytes/4096))
prnt "    Light Weight Trace memory"  $lmt_pgs  P
}


#lvm memory
do_lvm_mem()
{
totpbufs=0
for vg in `lsvg -o`; do
	pbufcnt=`lvmo -v $vg -o total_vg_pbufs|awk '{print $NF}'`
	totpbufs=$((totpbufs+pbufcnt))
done
	
#num_powerdisks=`lspv | grep hdiskpower | wc -l`    # need to check on a system with a hdiskpower disk and no VG on it
#if [ $num_powerdisks = 0 ]; then
#	num_disks=`lspv | grep -v None|wc -l`
#else
#	num_disks=$num_powerdisks
#fi
chk_memory_affinity=`vmo -F -a | grep memory_affinity | awk '{print $3}'`
if [ "$kerneltype" = 64 ]; then
	pbufsz=464
else
	pbufsz=236
fi
if [ "$chk_memory_affinity" = 0 ]; then 
#	lvm_memory=$((pbufsz*512*num_disks))
	lvm_memory=$((pbufsz*totpbufs))
else # multiply by max srads
#     	lvm_memory=$((pbufsz*512*16*num_disks))
     	lvm_memory=$((pbufsz*16*totpbufs))
fi
lvm_pgs=$((lvm_memory/4096))
prnt "    LVM Memory"          $lvm_pgs  P
}

do_xm_heap()
{
echo "xm -qu" | /usr/sbin/kdb > $kdbxmfile

totalxmheap=0
awk 'BEGIN { } /^----------/ { 
           while (status=getline>0) {
		a="0x"$1;printf("%d %s\n",a, $4)
           }
       }' $kdbxmfile | while read size name; do
		if [ $size != 0 ]; then
			prnt "        $name" $size B
			let totalxmheap=totalxmheap+size
		fi
	done
tot_xmheap_pgs=$((totalxmheap/4096))
}

do_kernelheap()
{
grep "kernel heap" $svsfile  > $svsfile.kheap
kheap_mem_pgs=`do_svmon_sids $svsfile.kheap`
#kheap_mem_pgs=`grep "kernel heap" $svsfile |awk 'BEGIN {s=0}{s=s+$7}END {print s}'`
#echo "====================================================|=========|==========="
prnt "    Total Kernel Heap memory       "  $kheap_mem_pgs  P
#echo "----------------------------------------------------|---------|-----------"
	do_jfs2_mem
tot_xmheap_pgs=0
if [ -n "$do_detailed_kheap" ]; then
	do_xm_heap
fi
misc_kheap=$((kheap_mem_pgs-tot_jfs2_mem_pgs-tot_xmheap_pgs))
prnt "        misc kernel heap"  $misc_kheap  P
#echo "====================================================|=========|==========="
#echo "----------------------------------------------------|---------|-----------"
}

do_jfs2_mem()
{
echo "pile" | kdb | grep "^0x" > $pileout 
tot=0; bp_pgs=0; ic_pgs=0; rest_pgs=0
while read ad nm pg; do
        pgs=`printf "%d" $pg`
        let tot=tot+pgs
        if [ "$nm" = "j2VCBufferPool" ]; then
                let bp_pgs=bp_pgs+pgs
        elif [ "$nm" = "iCache" ]; then
                let ic_pgs=ic_pgs+pgs
        elif [ "$nm" = "txLockPile" ]; then
                txLockPile=$pgs
		let tot=tot-pgs	# ignore txLockPile for now 
	elif [ "$nm" = "bmXBufPile" ]; then
		let tot=tot-pgs    # this is already part of metadata_size
        else
                let rest_pgs=rest_pgs+pgs
        fi
done < $pileout
metasz=`cat /proc/sys/fs/jfs2/memory_usage|grep "metadata cache"|awk '{print $NF}'`
tot_jfs2_mem_bytes=$((metasz+tot*4096))
tot_jfs2_mem_pgs=$((tot+metasz/4096))
prnt "        JFS2 total non-file memory"         $tot_jfs2_mem_pgs  P
prnt "            metadata_cache" $metasz B
prnt "            inode_cache" $ic_pgs P
prnt "            fs bufstructs"  $bp_pgs  P
prnt "            misc jfs2"  $rest_pgs P
}

do_files()
{
grep "file pages" $vmstatvfile | read total_file_pages junk1 junk2
grep "client pages" $vmstatvfile | read client_file_pages junk1 junk2
let pers_file_pages=total_file_pages-client_file_pages
prnt "    Total file memory"  $total_file_pages P
prnt "        Total clnt (JFS2, NFS,...) file memory"  $client_file_pages P
prnt "        Total pers (JFS) memory"  $pers_file_pages P
do_text
}

do_text()
{
global_clntpgs=`grep "^in use" $svgfile |awk '{print $5}'`
global_perspgs=`grep "^in use" $svgfile |awk '{print $4}'`
grep "clnt code" $svslfile > clntcode.out  #MATT
grep "pers code" $svslfile > perscode.out  #MATT
clnttext_proc_pgs=`do_svmon_sids clntcode.out`  #MATT
perstext_proc_pgs=`do_svmon_sids perscode.out`  #MATT
let totaltext_proc_pgs=clnttext_proc_pgs+perstext_proc_pgs  #MATT
let clnttextpgs=global_clntpgs-client_file_pages
let perstextpgs=global_perspgs-pers_file_pages
let totaltextpgs=clnttextpgs+perstextpgs
prnt "    Total text memory" $totaltextpgs P
prnt "        Total clnt text memory"  $clnttextpgs  P
prnt "        Total pers text memory"  $perstextpgs  P
}




do_svmon_sids()
{
svsfile_sids=$1
svmon_sids_mem=0
grep -v Vsid $svsfile_sids|awk '{print substr($0,54,1),substr($0,56,6)}'|while read sz pg; do
        case "$sz" in
                's') pgs=$pg;;  # small pages or 4K
                'm') let pgs=pg*16;;  # medium pages or 64K
                'L') let pgs=pg*4096;; # large pages or 16MB
                'S') let pgs=pg*4194304;;  # huge pages or 16GB
                *)      pgs=0;;    # don't know 
        esac
        let svmon_sids_mem=svmon_sids_mem+pgs
done
if [ "$svmon_sids_mem" = "" ]; then
	echo "0"
else
	echo $svmon_sids_mem
fi
}

do_detailed_system_segs()
{
grep "work" $svskfile | cut -c25-52 > $svskfiledesc
sort -u $svskfiledesc > $svskfiledesc.uniq
ident_ksegpgs=0
while read desc; do
	if [ "$desc" = "" ]; then
		continue
	fi
	grep  -w "$desc" $svskfile > $svskfiledesc.x
	ssegpgs=`do_svmon_sids $svskfiledesc.x`
	let ident_ksegpgs=ident_ksegpgs+ssegpgs
	prnt "        $desc"   $ssegpgs P
done < $svskfiledesc.uniq
let ksids_wo_desc=total_svmon_sids_kernel_mem-ident_ksegpgs
prnt "        miscellaneous kernel segs" $ksids_wo_desc P
#prnt "        --------------------------------" " " " "
#prnt "        Total kernel segments w/ description" $tssegpgs P
#prnt "        Total kernel segments w/o description" $ksids_wo_desc  P
}


do_svmon_sids_all()
{
prnt "Segment Overview" "Pages" "Megabytes"
echo "----------------------------------------------------|---------|-----------"
total_svmon_sids_pgs=`do_svmon_sids $svsfile`
prnt "Total segment id mempgs" $total_svmon_sids_pgs P
total_svmon_sids_kernel_mem=`do_svmon_sids $svskfile`
grep "fork tree" $svsfile > $svsfile.forktree
forktree_pgs=`do_svmon_sids $svsfile.forktree`
prnt "    Total fork tree segment pages" $forktree_pgs P
prnt "    Total kernel segment id mempgs" $total_svmon_sids_kernel_mem  P
}



do_unaccounted()
{
tot_mem_not_acct_pgs=$((tot_mem_pgs-free_pgs-total_svmon_sids_pgs-lgpg_pool_fr_4Kpgs-hgpg_pool_fr_4Kpgs-mem_wo_vmm_segids_dec))
echo
prnt "Unaccounted memory (no sids nor wlm_hw_pages)" $tot_mem_not_acct_pgs P
}

do_nosids()
{
mem_wo_vmm_segids_hex=`echo "dd wlm_hw_pages 1" | kdb | grep wlm_hw_pages+ | awk '{print $2}'`
mem_wo_vmm_segids_dec=`echo "ibase=16;$mem_wo_vmm_segids_hex" | bc`
echo
prnt "Total kernel mem w/ no segment id (wlm_hw_pages)"  $mem_wo_vmm_segids_dec   P
}

do_detailed_nosids()
{
echo "rmap *" | /usr/sbin/kdb > $rmapfile
echo "iplcb -mem" | /usr/sbin/kdb > $iplcbfile
total_nosids_bytes=0
#grep "^vmrmap" $MEMFILEDIR/rmap.kdb.out | awk '{print $7, $8}' | while read a b
#for item in RMALLOC PVT PVLIST "s/w PFT"
# can't use PVT and PVLIST values accurately here due to reuse, so do the hardway
for item in RMALLOC 
do
#	if [ "$b" = "" ]; then
#		item="$a"
#	else
#        	item="$a $b"
#	fi
	#bytes_hex=`grep "^vmrmap.*$item" $rmapfile | awk '{print $5}'`
	bytes_hex=`grep "^[0-9].  .*$item" $rmapfile | awk '{print $4}'`

	bytes_dec=`printf "%d" "0x${bytes_hex}"`
	prnt "    $item" $bytes_dec  B
	let total_nosids_bytes=total_nosids_bytes+bytes_dec
done

if [ "$kerneltype" = 64 ]; then
	sizeof_swpft_entry=96
	sizeof_pvt_entry=8
else
	sizeof_swpft_entry=60	
	sizeof_pvt_entry=8	
fi
number_of_frames=`grep "memory pages" $vmstatvfile | awk '{print $1}'`
let swpft_bytes=sizeof_swpft_entry*number_of_frames
prnt "    SW_PFT" $swpft_bytes B
let pvt_bytes=sizeof_pvt_entry*number_of_frames
prnt "    PVT" $pvt_bytes B

# get PVLIST size
hashbits_hex=`echo "vmker -seg"|/usr/sbin/kdb|grep "^hashbits"|awk '{print $NF}'`
hashbits=`printf "%d" "0x${hashbits_hex}"`
pvlist_bytes=`echo "8*8*2^$hashbits" | /usr/bin/bc`
prnt "    PVLIST" $pvlist_bytes  B

let total_nosids_bytes=total_nosids_bytes+swpft_bytes+pvt_bytes+pvlist_bytes


for item in RTAS_HEAP
do
	bytes_hex=`grep "$item" $iplcbfile | awk '{print $3}'`
	bytes_dec=`printf "%d" "0x${bytes_hex}"`
	prnt "    $item" $bytes_dec B
	let total_nosids_bytes=total_nosids_bytes+bytes_dec
done

prnt "    -----------------------------" "" ""
prnt "    Total"  $total_nosids_bytes  B
}

do_detailed()
{
echo "\n==========================================================================="
prnt "Detailed Memory Components" "Pages" "Megabytes"
echo "----------------------------------------------------|----------|-----------"
do_lmt_mem
do_lvm_mem
do_kernelheap
do_files
do_users
echo "==========================================================================="
}

do_users()
{

ps -e -o user= | grep "[A-Z,a-z,0-9]" | sort -u  > $all_user_file  
uniq_users=`wc -l $all_user_file|awk '{print $1}'`

if [ "$uniq_users" -gt $user_threshold ]; then
	do_detailed_users=0
	egrep 'shmat|mmap|shared memory' $svpfile | sort -k f1 -u > $svufile.shm.all_uniq
	total_allusers_shared_pgs=`do_svmon_sids $svufile.shm.all_uniq`
	egrep -v 'shmat|mmap|shared memory|clnt|pers|shared library text' $svpfile |sort -k f1 -u >$svufile.EXC.priv
	total_allusers_priv_pgs=`do_svmon_sids $svufile.EXC.priv`
	egrep 'shared library text' $svpfile|sort -k f1 -u > $svufile.shtext
	total_allusers_shtxt_pgs=`do_svmon_sids $svufile.shtext`

else

prnt "    User memory" ""  ""
total_allusers_priv_pgs=0
total_allusers_shtxt_exc_pgs=0
> $svufile.shm.all
> $svufile.shtext
# EXC=exclusive, SHA=shared
while read user; do
	svmon -U $user > $svufile  

	for type in clnt pers work; do
	  grep -p"\...." EXCLUSIVE $svufile |grep $type > $svufile.EXC.$type
	  let user_exc_${type}_pgs=`do_svmon_sids $svufile.EXC.$type`
	  grep -p"\...." SHARED $svufile |grep $type > $svufile.SHA.$type
	  let user_sha_${type}_pgs=`do_svmon_sids $svufile.SHA.$type`
	done

	egrep 'shmat|mmap|shared memory' ${svufile}.EXC.work > ${svufile}.EXC.shm
	egrep 'shmat|mmap|shared memory' ${svufile}.SHA.work > ${svufile}.SHA.shm
	cat ${svufile}.EXC.shm ${svufile}.SHA.shm >> ${svufile}.shm.all
	egrep 'stack|private|data|heap|working storage' $svufile.EXC.work > ${svufile}.EXC.priv   #MATT
	#egrep 'working storage' $svufile.EXC.work > ${svufile}.EXC.workstor #MATT
	egrep 'shared library text' ${svufile}.EXC.work > ${svufile}.shtext.priv
	egrep 'shared library text' ${svufile}.SHA.work > ${svufile}.shtext.sha
	cat ${svufile}.shtext.sha >> $svufile.shtext
	user_exc_shtxt_pgs=`do_svmon_sids $svufile.shtext.priv`
	let total_allusers_shtxt_exc_pgs=total_allusers_shtxt_exc_pgs+user_exc_shtxt_pgs
	user_sha_shtxt_pgs=`do_svmon_sids $svufile.shtext.sha`
        user_sha_shm_pgs=`do_svmon_sids $svufile.SHA.shm`
        user_exc_shm_pgs=`do_svmon_sids $svufile.EXC.shm`
	user_exc_priv_pgs=`do_svmon_sids $svufile.EXC.priv`
	#user_exc_wstor_pgs=`do_svmon_sids $svufile.EXC.workstor` #MATT
	let total_allusers_priv_pgs=total_allusers_priv_pgs+user_exc_priv_pgs

	let user_tot_clnt_pgs=user_exc_clnt_pgs+user_sha_clnt_pgs
	let user_tot_pers_pgs=user_exc_pers_pgs+user_sha_pers_pgs
	let user_tot_file_pgs=user_tot_clnt_pgs+user_tot_pers_pgs
	let user_tot_file_exc_pgs=user_exc_clnt_pgs+user_exc_pers_pgs
	let user_tot_file_sha_pgs=user_sha_clnt_pgs+user_sha_pers_pgs


	prnt "     USER: $user"
	prnt "       total process private memory" $user_exc_priv_pgs P
	if  echo "$user" |grep oracle >/dev/null ; then
		shm_name="[SGA]" # shared global area
	elif  echo "$user" |grep db2 >/dev/null ; then
		shm_name="[AGSM]" #application group shared memory
	fi
	prnt "       total shared memory $shm_name" $((user_sha_shm_pgs+user_exc_shm_pgs)) P
	prnt "       working (shared w/ other users)" $user_sha_work_pgs P
	prnt "       working (exclusive to user)" $user_exc_work_pgs  P
	prnt "          shared memory (exclusive to user)" $user_exc_shm_pgs P
	prnt "          shared memory (shared w/ other users)" $user_sha_shm_pgs P
	prnt "       shlib text (shared w/ other users)" $user_sha_shtxt_pgs P
	prnt "       shlib text (exclusive to user)" $user_exc_shtxt_pgs P
	prnt "       file pages" $user_tot_file_pgs P
	prnt "          file pages (exclusive to user)" $user_tot_file_pgs P
	prnt "          file pages (shared w/ other users)" $user_tot_file_sha_pgs P
done < $all_user_file
sort -k f1 -u $svufile.shtext > $svufile.shtext.uniq
total_allusers_shtxt_pgs=`do_svmon_sids $svufile.shtext.uniq`
let total_allusers_shtxt_pgs=total_allusers_shtxt_pgs+total_allusers_shtxt_exc_pgs
fi
}

do_summary()
{
echo "\n\n"
echo "==========================================================================="
if [ "$do_detailed_users" = 1 ]; then
	#awk '{print $1}' $svufile.shm.all |sort -u > $svufile.shm.all_uniq.sids
	#> $svufile.shm.all_uniq
	#while read sid; do
	#	grep -w "$sid .*work" $svufile.shm.all >> $svufile.shm.all_uniq
	#done < $svufile.shm.all_uniq.sids
	sort -k f1 -u $svufile.shm.all > $svufile.shm.all_uniq
	total_allusers_shared_pgs=`do_svmon_sids $svufile.shm.all_uniq`
fi
ident_kmem=$((ident_ksegpgs+mem_wo_vmm_segids_dec))
total_iden_inuse=$((ident_kmem+totaltextpgs+total_file_pages+total_allusers_shared_pgs+total_allusers_priv_pgs+forktree_pgs+lgpg_pool_fr_4Kpgs+hgpg_pool_fr_4Kpgs+total_allusers_shtxt_pgs))
prnt "Memory accounting summary" "4K Pages" "Megabytes"
echo "----------------------------------------------------|----------|-----------"
prnt "Total memory in system" $tot_mem_pgs P
prnt "  Total memory in use"  $tot_inuse_pgs P 
prnt "     Kernel identified memory (segids,wlm_hw_pages)"  $ident_kmem P
prnt "     Kernel un-identified memory "   $ksids_wo_desc P
prnt "     Fork tree pages" $forktree_pgs P
prnt "     Large Page Pool free pages" $lgpg_pool_fr L
prnt "     Huge Page Pool free pages" $hgpg_pool_fr  S
prnt "     User private memory"  $total_allusers_priv_pgs P
prnt "     User shared memory"  $total_allusers_shared_pgs P
prnt "     User shared library text memory" $total_allusers_shtxt_pgs P
#prnt "     Text memory" $totaltextpgs  P   #MATT
let text_not_in_use=totaltextpgs-totaltext_proc_pgs  #MATT
prnt "     Text/Executable code memory in use" $totaltext_proc_pgs P  #MATT
prnt "     Text/Executable code memory not in use" $text_not_in_use P  #MATT
prnt "     File memory"  $total_file_pages P
user_unident=$((tot_inuse_pgs-total_iden_inuse-ksids_wo_desc)) 
prnt "     User un-identifed memory "  $user_unident P
prnt "     ----------------------" " "  " "
prnt "     Total accounted in-use" $((total_iden_inuse+ksids_wo_desc+user_unident)) P
prnt "  Free memory"  $free_pgs P
prnt "  ----------------------" ""  ""
prnt "  Total identified (total ident.+free)" $((total_iden_inuse+free_pgs)) P
prnt "  Total unidentified (kernel+user w/ segids)" $((ksids_wo_desc+user_unident)) P
prnt "  ----------------------" ""  ""
prnt "  Total accounted" $((total_iden_inuse+free_pgs+ksids_wo_desc+user_unident)) P

tot_mem_not_acct_pgs=$((tot_mem_pgs-free_pgs-total_svmon_sids_pgs-lgpg_pool_fr_4Kpgs-hgpg_pool_fr_4Kpgs-mem_wo_vmm_segids_dec))
prnt "  Total unaccounted" $tot_mem_not_acct_pgs P

echo "\nUnidentifed user could be: "
echo " - shared memory segments currently not attached by processes"
echo " - shared libraries currently not used by any processes"
echo " - miscellaneous"
echo "==========================================================================="
}

do_cleanup()
{
/bin/rm ${svufile}.EXC.* ${svufile}.SHA.* 
/bin/rm $svufile.shm.all_uniq $svufile.shm.all_uniq.sids $svufile.shm.all $all_user_file
/bin/rm $svskfiledesc $svskfiledesc.x; rm $svskfiledesc.uniq
/bin/rm $svufile $svgfile $svsfile $svskfile  $vmstatvfile
/bin/rm $rmapfile $iplcbfile $pileout
/bin/rm $svsfile.forktree $svsfile.kheap
/bin/rm $svpfile $svufile.shtext
}

#MEMFILEDIR=/tmp
MEMFILEDIR=$PWD
svufile=$MEMFILEDIR/svmon_U.out
svgfile=$MEMFILEDIR/svmon_G.out
svsfile=$MEMFILEDIR/svmon_S.out
svskfile=$MEMFILEDIR/svmon_Ss.out
svslfile=$MEMFILEDIR/svmon_Sl.out #MATT
svskfiledesc=$MEMFILEDIR/svmon_ksids.desc
svpfile=$MEMFILEDIR/svmon_P.out
vmstatvfile=$MEMFILEDIR/vmstat.v.out
rmapfile=$MEMFILEDIR/rmap.kdb.out
iplcbfile=$MEMFILEDIR/iplcb.kdb.out
pileout=$MEMFILEDIR/pile.kdb.out
kdbxmfile=$MEMFILEDIR/xm.kdb.out
all_user_file=$MEMFILEDIR/all_users.out
kerneltype=`bootinfo -K`
PROG=$0
user_threshold=20   # if more unique user id's running than this, then don't do detailed user stats

show_usage()
{
	echo "Usage: $PROG [-x][-u usercount]"
	echo "-x  show more details of kernel heap allocations"
	echo "-u  usercount   do not show details of each user if unique user ids is > usercount "
	exit 0
}

do_detailed_users=1
while getopts xu: flag ; do
        case $flag in
                x)     do_detailed_kheap=1;;
		u)     user_threshold=$OPTARG;;
                \?)     show_usage
        esac
done

collect_data 
do_total
do_svmon_sids_all
do_detailed_system_segs
do_nosids
do_detailed_nosids
do_total_acct
do_unaccounted
do_detailed
do_summary
#do_cleanup
