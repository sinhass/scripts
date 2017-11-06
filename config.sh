#!/bin/ksh
#
# COMPONENT_NAME: perfpmr
#
# FUNCTIONS: none
#
# ORIGINS: IBM
#
# (C) COPYRIGHT International Business Machines Corp. 2000,2001,2002,2003,2004,2005,2006,2007
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# config.sh
#
# invoke configuration commands and create report
#
#set -x
export LANG=C
PERFPMRDIR=`whence $0`
PERFPMRDIR=`/usr/bin/ls -l $PERFPMRDIR |/usr/bin/awk '{print $NF}'`
PERFPMRDIR=`/usr/bin/dirname $PERFPMRDIR`
unset EXTSHM

CFGOUT=config.sum
RESTNGOUT=tunables.sum
RESTNGOUTX=tunablesx.sum
BIN=/usr/bin
if [ "$GETGENNAMES" = 0 ]; then
        nogennames=1
fi

show_usage()
{
	echo "Usage: config.sh [-aglpsm -u usercount]"
	echo "\t-a  do not run lsattr on every device"
	echo "\t-g  do not run gennames command"
	echo "\t-l  do not run detailed LVM commands on each LV"
	echo "\t-p  do not run lspv on each disk"
	echo "\t-s  do not run SSA cfg commands"
	echo "\t-m  do not run detailed memory script"
	echo "\t-u  usercount do not collected detailed memory stats per user if number of unique user ids is greater than usercount"
	echo "\toutput is generated in $CFGOUT"
	exit 1
}

do_timestamp()
{
        echo "`/bin/date +"%H:%M:%S-%D"` :\t$1"
}


detailed_mem_flag=1
while getopts :gslaprQmu: flag ; do
        case $flag in
		Q)     quicker_cfg=1;;
		r)     do_report=1;;
                p)     nolspv=1;;
                g)     nogennames=1;;
                s)     nossa=1;;
                l)     nolv=1;;
                a)     nolsattr=1;;
		m)     detailed_mem_flag=0;;
		u)     user_threshold_flag="-u $OPTARG";;
                \?)    show_usage
        esac
done


do_config_begin()
{
do_timestamp "config.sh begin"
echo "\n     CONFIG.SH: Generating SW/HW configuration"

echo "\n\n\n        C O N F I G U R A T I O N     S  U  M  M  A  R  Y     O  U  T  P  U  T\n\n\n" > $CFGOUT
echo "\n\nHostname:  "  `$BIN/hostname -s` >> $CFGOUT
echo     "Time config run:  " `$BIN/date` >> $CFGOUT
echo     "AIX VRLM (oslevel):  " `$BIN/oslevel` >> $CFGOUT

echo "\n\n\n        T U N A B L E S     O  U  T  P  U  T (-Fa)\n\n\n" > $RESTNGOUT
echo "\n\nHostname:  "  `$BIN/hostname -s` >> $RESTNGOUT
echo     "Time config run:  " `$BIN/date` >> $RESTNGOUT

echo "\n\n\n        T U N A B L E S     O  U  T  P  U  T (-x)\n\n\n" > $RESTNGOUTX
echo "\n\nHostname:  "  `$BIN/hostname -s` >> $RESTNGOUTX
echo     "Time config run:  \n" `$BIN/date` >> $RESTNGOUTX
}

do_uname()
{
echo "\n\nPROCESSOR TYPE  (uname -m)" >> $CFGOUT
echo     "--------------------------\n" >> $CFGOUT
$BIN/uname -m  >> $CFGOUT
echo     "        ## = model" >> $CFGOUT
}

do_mem()
{
echo "\n\nMEMORY  (bootinfo -r):  " `bootinfo -r`  >> $CFGOUT
echo     "MEMORY  (lscfg -l memN)" >> $CFGOUT
echo     "-----------------------\n"  >> $CFGOUT
lscfg -l mem* >> $CFGOUT
}

do_kdb_swpft()
{
echo "\n\nMEMORY (dd wlm_hw_pages/vmker -psize)\n----------------------" >> $CFGOUT
#echo "dd wlm_hw_pages\n\nvmker -psize\n\nppda *" | /usr/sbin/kdb >> $CFGOUT
echo "dd wlm_hw_pages\n\nvmstat\nvmstat -p 0\nvmstat -p1\nfrs *\npst *\npst 0\npst 1\npfhdata\nvmker\nvmker -psize\n\nppda *\n\ndw hcall_stats_flag" | /usr/sbin/kdb >> $CFGOUT 
}


do_lsps()
{
# get current paging space info
echo "\n\nPAGING SPACES  (lsps -a)" >> $CFGOUT
echo     "------------------------\n" >> $CFGOUT
lsps -a  >> $CFGOUT

echo "\n\nPAGING SPACES  (lsps -s)" >> $CFGOUT
echo     "------------------------\n" >> $CFGOUT
lsps -s  >> $CFGOUT
}

do_ipcs()
{
do_timestamp "ipcs -Smqsa"
echo "\n\nINTERPROCESS COMMUNICATION FACILITY STATUS (ipcs -Smqsa)" >> $CFGOUT
echo     "----------------------------------------------------\n" >> $CFGOUT
$BIN/ipcs -Smqsa  >> $CFGOUT
}

do_lsdev()
{
# get detail device info
echo "\f\n\nPHYSICAL / LOGICAL DEVICE DETAILS  (lsdev -C | sort +2)" >> $CFGOUT
echo       "-------------------------------------------------------\n" >> $CFGOUT
/usr/sbin/lsdev -C | $BIN/sort +2 >> $CFGOUT
}


do_lspv()
{
# get current physical volume names
echo "\f\n\nPHYSICAL VOLUMES  (lspv)" >> $CFGOUT
echo       "------------------------\n" >> $CFGOUT
/usr/sbin/lspv  >> $CFGOUT
}

do_lspv_l()
{
# get detail physical volume info
if [ ! -n "$nolspv" ]; then
 do_timestamp "lspv -l"
 for i in `/usr/sbin/lspv | $BIN/awk '{print $1}'`; do
    echo "\n\nPHYSICAL VOLUME DETAILS FOR $i  (/usr/sbin/lspv -l $i)" >> $CFGOUT
    echo     "------------------------------------------------------\n" >> $CFGOUT
    /usr/sbin/lspv -l $i >> $CFGOUT   2>&1
 done
fi
}

do_lspv_new()
{
# get current physical volume names
do_timestamp "lspv "
echo "\f\n\nPHYSICAL VOLUMES  (lspv)" >> $CFGOUT
echo       "------------------------\n\n" >> $CFGOUT
/usr/sbin/lspv  |while read line; do
    echo "$line"
    if [ ! -n "$nolspv" ]; then
	set $line
	if [ "$2" != "none" ]; then
    		echo "\n\nPHYSICAL VOLUME DETAILS FOR $i  (/usr/sbin/lspv -l $i)" 
    		echo     "------------------------------------------------------\n"
		/usr/sbin/lspv -l $1
		echo "\n\n"
	fi
    fi
done >> $CFGOUT
}


do_lsvg()
{
# get volume group info
do_timestamp "lsvg "
for i in `/usr/sbin/lsvg -o`; do
  echo "\n\nVOLUME GROUP DETAILS  (/usr/sbin/lsvg  $i)" >> $CFGOUT
  echo     "-------------------------------------------\n" >> $CFGOUT
  /usr/sbin/lsvg  $i >> $CFGOUT
done
}

do_lsvg_l()
{
# get detail volume group info
do_timestamp "lsvg -l"
for i in `/usr/sbin/lsvg -o`; do
  echo "\n\nVOLUME GROUP DETAILS  (/usr/sbin/lsvg -l $i)" >> $CFGOUT
  echo     "-------------------------------------------\n" >> $CFGOUT
  /usr/sbin/lsvg -l $i >> $CFGOUT
done
}

do_mount()
{

# get current mount info
echo "\f\n\nMOUNTED FILESYSTEMS  (mount)" >> $CFGOUT
echo       "----------------------------\n" >> $CFGOUT
/usr/sbin/mount  >> $CFGOUT
}


do_lsfs()
{
echo "\n\nFILE SYSTEM INFORMATION:  (lsfs -q)"  >> $CFGOUT
echo     "-----------------------------------\n" >> $CFGOUT
/usr/sbin/lsfs -q  >>  $CFGOUT   2>&1
}

do_df()
{
echo "\n\nFILE SYSTEM SPACE:  (df)"  >> $CFGOUT
echo     "------------------------\n" >> $CFGOUT
do_timestamp "df"
$BIN/df    >>  $CFGOUT &
dfpid=$!
dfi=0;dftimeout=30
while [ $dfi -lt $dftimeout ]; do
        /usr/bin/ps -p $dfpid >/dev/null
        if [ $? = 0 ]; then
                sleep 2
        else
                break
        fi
        let dfi=dfi+1
done
if [ "$dfi" = $dftimeout ]; then
        echo "Killing <df> process"
        kill -9 $dfpid
fi
}


do_lslv()
{
if [ ! -n "$nolv" ]; then
do_timestamp "lslv lv"
# for LV in $(/usr/sbin/lsvg -o|/usr/sbin/lsvg -il|$BIN/awk '{print $1}'|$BIN/egrep -v ':|LV') ; do
 for LV in $(/usr/sbin/lsvg -o|/usr/sbin/lsvg -il|$BIN/awk '{if ($2 != "NAME") print $1}' | grep -v ':'); do
   echo "\n\nLOGICAL VOLUME DETAILS   (/usr/sbin/lslv $LV)"
   echo     "---------------------------------------\n"
   /usr/sbin/lslv $LV
   echo
   /usr/sbin/lslv -l $LV
   echo
 done >> $CFGOUT
fi
}


do_quicksnap()
{
# ======================= ESS CFG INFO =====================
#$PERFPMRDIR/quicksnap.sh > quicksnap.out
:
}

do_fastt()
{
# ============================= FASTT CFG ====================================
  fget_config -vA > fastt.out
}

do_ssa()
{
# ============================= SSA CFG ====================================

if [ ! -n "$nossa" ]; then
  echo "\n\nMapping of SSA hdisk to pdisk" >> $CFGOUT
  echo     "-----------------------------\n" >> $CFGOUT
  for i in $(lsdev -Csssar -thdisk -Fname)
  do
    echo "ssaxlate -l $i: `/usr/sbin/ssaxlate -l $i`"  >> $CFGOUT
  done

  echo "\n\nMapping of SSA pdisk to hdisk" >> $CFGOUT
  echo     "-----------------------------\n" >> $CFGOUT
  for i in $(lsdev -Csssar -cpdisk -Fname)
  do
    echo "ssaxlate -l $i: `/usr/sbin/ssaxlate -l $i`"   >> $CFGOUT
  done

  echo "\n\nSSA connection data (ssaconn -l pdiskN -a ssaN)" >> $CFGOUT
  echo     "-----------------------------------------------\n" >> $CFGOUT
  for pdisk in $(/usr/sbin/lsdev -Csssar -cpdisk -Fname)
  do
      for adap in $(/usr/sbin/ssaadap -l $pdisk 2>/dev/null)
      do
        /usr/sbin/ssaconn -l $pdisk -a $adap    >> $CFGOUT
      done
  done

  echo "\n\nSSA connection data sorted by link" >> $CFGOUT
  echo "(ssaconn -l all_pdisks -a all_ssa_adapters | $BIN/sort -d +4 -5 +2 -3)"   >> $CFGOUT
  echo "-----------------------------------------------------------------"  >> $CFGOUT
  unset Cssa
  for adap in $(/usr/sbin/lsdev -Ctssa -Fname) $(lsdev -Ctssa160 -Fname)
  do
    for pdisk in $(/usr/sbin/lsdev -Csssar -cpdisk -Fname)
    do
      xssa=$(/usr/sbin/ssaconn -l $pdisk -a $adap 2>/dev/null )
      if [[ -n $xssa ]]
      then
        Cssa="$Cssa\\n$xssa"
      fi
    done
    echo "$Cssa" | $BIN/sort -d +4 -5 +2 -3      >> $CFGOUT
    unset Cssa
    unset string
  done

  for adap in $(/usr/sbin/ssaraid -M 2>/dev/null)
  do
    echo "\n\nssaraid -l $adap -I"    >> $CFGOUT
    echo     "-------------------"   >> $CFGOUT
    /usr/sbin/ssaraid -l $adap -I           >> $CFGOUT
  done

fi   # no ssa

# =====================   END OF SSA CFG ===================================
}


do_netstat()
{
# get static network configuration info
echo "\f\n\nNETWORK  CONFIGURATION  INFORMATION" >> $CFGOUT
echo       "-----------------------------------\n" >> $CFGOUT
do_timestamp "netstat -in -rn -D -an -c"
for i in  in rn D an c
do
  echo "netstat -$i:"  >> $CFGOUT
  echo "------------\n"  >> $CFGOUT
  $BIN/netstat -$i >> $CFGOUT
  echo "\n\n" >> $CFGOUT
done
}


do_ifconfig()
{
echo "\n\nINTERFACE CONFIGURATION:  (ifconfig -a)" >> $CFGOUT
echo     "------------------------\n"  >> $CFGOUT
/usr/sbin/ifconfig -a >>  $CFGOUT
}

do_no()
{
echo "\n\nNETWORK OPTIONS:  (no -a)" >> $CFGOUT
echo     "-------------------------\n"  >> $CFGOUT
no -a >>  $CFGOUT
}

do_nfso()
{
echo "\n\nNFS OPTIONS:  (nfso -a)" >> $CFGOUT
echo     "-----------------------\n"  >> $CFGOUT
nfso -a >>  $CFGOUT
}


do_showmount()
{
echo "\n\nshowmount -a" >> $CFGOUT
echo     "------------\n"  >> $CFGOUT
$BIN/showmount -a      >>  $CFGOUT    2>&1
}


do_lsattr()
{
# Capture all lsattr settings
do_timestamp "lsattr -E -l dev"
if [ ! -n "$nolsattr" ]; then
  /usr/sbin/lsdev -C -r name | while read DEVS; do
      	echo "\n\nlsattr -E -l $DEVS"
      	echo     "--------------------"
      	/usr/sbin/lsattr -E -l $DEVS  2>&1
  done >> $CFGOUT
fi
}


do_cp_tunables()
{
# get tuning files
/usr/bin/cp /etc/tunables/nextboot tunables_nextboot
/usr/bin/cp /etc/tunables/lastboot tunables_lastboot
/usr/bin/cp /etc/tunables/lastboot.log tunables_lastboot.log
}



do_schedo()
{
# collect schedo current settings
echo "\n\nSCHEDO SETTINGS   (schedo)" >> $CFGOUT
echo     "--------------------------------\n"  >> $CFGOUT
if [ -f /usr/sbin/schedo ]; then
     /usr/sbin/schedo -a >> $CFGOUT
else
     echo "/usr/sbin/schedo not installed" >> $CFGOUT
     echo "   This program is part of the bos.perf.tune fileset" >> $CFGOUT
fi
}


do_vmo_vmstat_v()
{
echo "\n\nVMO SETTINGS  (vmo)" >> $CFGOUT
echo     "-------------------------\n"  >> $CFGOUT
if [ -f /usr/sbin/vmo ]; then
     /usr/sbin/vmo -a >> $CFGOUT
     echo "\n\nIOO SETTINGS  (ioo -a)" >> $CFGOUT
     echo     "----------------------------\n"  >> $CFGOUT
     /usr/sbin/ioo -a   >> $CFGOUT 2>&1
     echo "\n\nVMSTAT -v SETTINGS  (vmstat -v)" >> $CFGOUT
     echo     "----------------------------\n"  >> $CFGOUT
     /usr/bin/vmstat -v   >> $CFGOUT   2>&1
else
     echo "kernel tuning tools not installed" >> $CFGOUT
     echo "   These programs are part of the bos.perf.tune fileset" >> $CFGOUT
fi
}

do_tunables_FL()
{
echo "\n\nVMO SETTINGS  (vmo -Fa)" >> $RESTNGOUT
echo     "-------------------------\n"  >> $RESTNGOUT
if [ -f /usr/sbin/vmo ]; then
     /usr/sbin/vmo -Fa >> $RESTNGOUT
     echo "\n\nIOO SETTINGS  (ioo -Fa)" >> $RESTNGOUT
     echo     "----------------------------\n"  >> $RESTNGOUT
     /usr/sbin/ioo -Fa   >> $RESTNGOUT 2>&1
     echo "\n\nSCHEDO SETTINGS   (schedo -Fa)" >> $RESTNGOUT
     echo     "--------------------------------\n"  >> $RESTNGOUT
     /usr/sbin/schedo -Fa >> $RESTNGOUT 2>&1
     echo "\n\nNETWORK OPTIONS:  (no -Fa)" >> $RESTNGOUT
     echo     "-------------------------\n"  >> $RESTNGOUT
     /usr/sbin/no -Fa >>  $RESTNGOUT

     echo "\n\nVMO SETTINGS  (vmo -FL)" >> $RESTNGOUT
     echo     "-------------------------\n"  >> $RESTNGOUT
     /usr/sbin/vmo -FL >> $RESTNGOUT
     echo "\n\nIOO SETTINGS  (ioo -FL)" >> $RESTNGOUT
     echo     "----------------------------\n"  >> $RESTNGOUT
     /usr/sbin/ioo -FL   >> $RESTNGOUT 2>&1
     echo "\n\nSCHEDO SETTINGS   (schedo)" >> $RESTNGOUT
     echo     "--------------------------------\n"  >> $RESTNGOUT
     /usr/sbin/schedo -FL >> $RESTNGOUT 2>&1
     echo "\n\nNETWORK OPTIONS:  (no -FL)" >> $RESTNGOUT
     echo     "-------------------------\n"  >> $RESTNGOUT
     /usr/sbin/no -FL >>  $RESTNGOUT
else
     echo "kernel tuning tools not installed" >> $RESTNGOUT
     echo "   These programs are part of the bos.perf.tune fileset" >> $RESTNGOUT
fi
}

do_tunables_x()
{
echo "schedo -x" >> $RESTNGOUTX
schedo -x >> $RESTNGOUTX
echo "vmo -x" >> $RESTNGOUTX
vmo -x >> $RESTNGOUTX
echo "ioo -x" >> $RESTNGOUTX
ioo -x >> $RESTNGOUTX
echo "no -x" >> $RESTNGOUTX
no -x >> $RESTNGOUTX
}

do_lvmo()
{
echo "\n\nLVMO SETTINGS  (lvmo)" >> $CFGOUT
echo     "-------------------------\n"  >> $CFGOUT
for l in `lsvg -o`; do
/usr/sbin/lvmo -v $l -a 
echo 
done >> $CFGOUT
echo     "----------------------------\n"  >> $CFGOUT
}

do_mempool()
{
# =====================  MEMPOOL STATISTICS ===============================
echo "\n\nMEMPOOL STATS (getmempool.sh  )" >> $CFGOUT
echo     "--------------------------------------------\n"  >> $CFGOUT
do_timestamp "getmempool.sh"
$PERFPMRDIR/getmempool.sh >> $CFGOUT
}


do_jfs2mem()
{
# =====================  JFS2 MEMORY STATISTICS ===============================
echo "\n\nJFS2 MEMORY STATS (getj2mem.sh  )" >> $CFGOUT
echo     "--------------------------------------------\n"  >> $CFGOUT
do_timestamp "getj2mem.sh"
$PERFPMRDIR/getj2mem.sh >> $CFGOUT
}
do_jfs2stats()
{
# =====================  JFS2 STATISTICS ===============================
echo "\n\nJFS2 STATS " >> $CFGOUT
echo     "--------------------------------------------\n"  >> $CFGOUT
cat /proc/sys/fs/jfs2/statistics >> $CFGOUT
}



do_wlm()
{
# =====================  WORKLOAD MANAGER ===============================
echo "\n\nworkload manager status  (wlmcntrl -q ; echo \$?)" >> $CFGOUT
echo     "-------------------------------------------------" >> $CFGOUT
wlmcntrl -q  2>&1 >> $CFGOUT
echo $?      >> $CFGOUT

echo "\n\nworkload manager classes (lsclass -C/lsclass -f)" >> $CFGOUT
echo     "-------------------------------------" >> $CFGOUT
 lsclass -C   >> $CFGOUT
 lsclass -f   >> $CFGOUT
# =====================  END OF WORKLOAD MANAGER ===========================
}



do_genkld()
{
# =====================  GEN* COMMANDS ===============================
# get genkld and genkex output
do_timestamp "genkld"
echo "\n\nGENKLD OUTPUT  (genkld)" >> $CFGOUT
echo     "-----------------------\n"  >> $CFGOUT
whence genkld > /dev/null  2>&1
if [ $? = 0 ]; then
     #genkld |$BIN/sort > genkld.out
     genkld  > genkld.out
else
     echo "genkld not installed or not in current PATH"  >> $CFGOUT
     echo "   This program is part of the bos.perf.tools fileset" >> $CFGOUT
fi
}

do_genkex()
{
echo "\n\nGENKEX OUTPUT  (genkex)" >> $CFGOUT
echo     "-----------------------\n"  >> $CFGOUT
do_timestamp "genkex"
whence genkex > /dev/null  2>&1
if [ $? = 0 ]; then
     #genkex | $BIN/sort >  genkex.out
     genkex  >  genkex.out
else
     echo "genkex not installed or not in current PATH"  >> $CFGOUT
     echo "   This program is part of the bos.perf.tools fileset" >> $CFGOUT
fi

# ==================  END OF GEN* COMMANDS ===============================
}


do_audit()
{
echo "\n\nSYSTEM AUDITING STATUS  (audit query)"    >> $CFGOUT
echo     "-------------------------------------\n"  >> $CFGOUT
audit query  >>  $CFGOUT
}


do_env()
{
echo "\n\nSHELL ENVIRONMENT  (env)"    >> $CFGOUT
echo     "------------------------\n"  >> $CFGOUT
env   >>  $CFGOUT
}

do_getevars()
{
echo "\n\nSHELL ENVIRONMENTS (getevars -l > getevars.out)" >> $CFGOUT
echo     "--------------------------------------------\n"  >> $CFGOUT
do_timestamp "getevars"
$PERFPMRDIR/getevars -l > getevars.out
}


do_errpt()
{
# get 2000 lines of verbose error report output
do_timestamp "errpt"
echo "\n\nVERBOSE ERROR REPORT   (errpt -a | head -2000 > errpt_a)" >> $CFGOUT
echo     "--------------------------------------------------------\n" >> $CFGOUT
$BIN/errpt -a | head -2000 > errpt_a
# get 100 most recent entries in errpt
echo "ERROR REPORT   (errpt | head -100)" >> $CFGOUT
echo "----------------------------------\n" >> $CFGOUT
$BIN/errpt | head -100  >> $CFGOUT
/bin/cp /var/adm/ras/errlog  errlog
/bin/cp /var/adm/ras/errtmplt  errtmplt
}

do_ifix_list()
{
do_timestamp "emgr -l"
echo "\n\nIFIXES INSTALLED (emgr -l)" >> $CFGOUT
echo
/usr/sbin/emgr -l >> $CFGOUT
}

do_lslpp()
{
# get lpp history info
do_timestamp "lslpp -ch"
echo "\f\n\nLICENSED  PROGRAM  PRODUCT  HISTORY  (lslpp -ch)" >> $CFGOUT
echo       "------------------------------------------------\n" >> $CFGOUT
/usr/bin/lslpp -ach >> $CFGOUT
/usr/bin/lslpp -Lc >> lslpp.Lc
}

do_instfix()
{
# get apar info
do_timestamp "instfix -ic"
instfix -ic > instfix.out
}

do_emgr()
{
do_timestamp "emgr -l"
echo "\n\n IFIX    (emgr -l )" >> $CFGOUT
echo       "------------------------------------------------\n" >> $CFGOUT
emgr -l >> $CFGOUT
}


do_java()
{
# get java lpp info
echo "\n\njava -fullversion" >> $CFGOUT
echo     "-----------------\n" >> $CFGOUT
whence java >> $CFGOUT  2>&1
if [ $? = 0 ]; then
    java -fullversion >> $CFGOUT    2>&1
fi
}


do_lsslot()
{
# get slot information
echo "\f\n\nPCI SLOT CONFIGURATION  (lsslot -c pci)" >> $CFGOUT
echo       "-----------------------------------------\n" >> $CFGOUT 
lsslot -c pci >> $CFGOUT 2>/dev/null
}


do_lscfg_vp()
{
# get verbose machine configuration
#  added because it is useful to tell between 601 and 604 upgrades
echo "\f\n\nVERBOSE MACHINE CONFIGURATION  (lscfg -vp)" >> $CFGOUT
echo       "-----------------------------------------\n" >> $CFGOUT
do_timestamp "lscfg -vp"
lscfg -vp  >> $CFGOUT
}


do_lsc()
{
# get cache info via Matt's program
echo "\f\n\nPROCESSOR DETAIL  (lsc -m)" >> $CFGOUT
echo       "--------------------------\n" >> $CFGOUT
$PERFPMRDIR/lsc -m >> $CFGOUT
}


do_kdb_th()
{
# get kproc and thread info AND kernel heap stats
echo "\n\nKERNEL THREAD TABLE  (pstat -A)" >> $CFGOUT
echo     "-------------------------------\n" >> $CFGOUT
# pstat may not work yet
do_timestamp "th *|kdb"
echo "th *" | /usr/sbin/kdb >> $CFGOUT
}

do_kdb_xm()
{
echo "\n\nKERNEL HEAP USAGE  (xm -u)" >> $CFGOUT
echo     "-------------------------------\n" >> $CFGOUT
do_timestamp "xm -u |kdb"
echo "xm -u" | /usr/sbin/kdb >> $CFGOUT
}


do_kdb_vnode_vfs()
{
# get vnode and vfs info
do_timestamp "echo vnode|kdb"
echo "vnode"|/usr/sbin/kdb > vnode.kdb
do_timestamp "echo vfs|kdb"
echo "vfs"|/usr/sbin/kdb > vfs.kdb
}


do_devtree()
{
# get devtree information
do_timestamp "echo dmpdt_chrp -i"
/usr/lib/boot/bin/dmpdt_chrp -i > devtree.out 2>&1
}


do_sysdumpdev()
{
# get system dump config info
echo "\n\nSYSTEM DUMP INFO (sysdumpdev -l;sysdumpdev -e)" >> $CFGOUT
echo     "----------------------------------------------\n" >> $CFGOUT
do_timestamp "sysdumpdev -l, -e"
sysdumpdev -l >> $CFGOUT
sysdumpdev -e >> $CFGOUT
}


do_bosdebug()
{
# get bosdebug settings
echo "\n\nbosdebug -L" >> $CFGOUT
echo     "-----------\n" >> $CFGOUT
bosdebug -L  >> $CFGOUT
}

do_locktrace()
{
# get locktrace settings
echo "\n\nlocktrace -l" >> $CFGOUT
echo     "-----------\n" >> $CFGOUT
locktrace -l  >> $CFGOUT 2>&1
}


do_unix()
{
# get ls of kernel in use
echo "\n\nls -al /unix INFO" >> $CFGOUT
echo     "-----------------" >> $CFGOUT
ls -al /unix  >> $CFGOUT
echo "\nls -al /usr/lib/boot/uni* INFO" >> $CFGOUT
echo   "------------------------------" >> $CFGOUT
ls -al /usr/lib/boot/uni*  >> $CFGOUT
}


do_pmctrl()
{
# get power management settings
echo "\n\npower management (pmctrl -v)" >> $CFGOUT
echo     "----------------------------\n" >> $CFGOUT
pmctrl -v  >> $CFGOUT  2>&1
}

do_rset()
{
# get rset information
echo "\n\nRSET (resource set) configuration" >> $CFGOUT
echo     "----------------------------\n" >> $CFGOUT
/usr/sbin/lsrset -a -v > lsrset.out
}


do_gennames()
{
# get gennames output if needed (not present or older than .init.state)
if [ ! -n "$nogennames" ]; then
	echo "\n\ngennames > gennames.out" >> $CFGOUT
	echo     "-----------------------\n" >> $CFGOUT
	if [ ! -f gennames.out -o gennames.out -ot /etc/.init.state ]; then
		do_timestamp "gennames"
     		gennames > gennames.out  2>&1
	fi
fi
}


do_crontab()
{
# get crontab -l info
echo "\n\ncrontab -l > crontab_l" >> $CFGOUT
echo     "----------------------\n" >> $CFGOUT
crontab -l > crontab_l
}


do_limits()
{
# get /etc/security/limits
echo "\n\ncp /etc/security/limits etc_security_limits" >> $CFGOUT
echo     "-------------------------------------------\n" >> $CFGOUT
cp /etc/security/limits etc_security_limits
}


do_initt_fs_rc()
{
# get misc files
/usr/bin/cp /etc/inittab  etc_inittab
/usr/bin/cp /etc/filesystems  etc_filesystems
/usr/bin/cp /etc/rc  etc_rc
}


do_what()
{
# get what output of /unix
/usr/bin/what /unix > unix.what
}


do_cfg_end()
{
echo "config.sh data collection completed." >> $CFGOUT
echo "     CONFIG.SH: Report is in file $CFGOUT"

###end of shell
do_timestamp "config.sh completed"
}

do_vio()
{
if [ -d /usr/ios ]; then
	do_timestamp "VIO cfg data"
	echo "------------ ioslevel  ----------" > vio.cfg
	/usr/ios/cli/ioscli ioslevel  > vio.cfg
	echo "\n\n------------ lsdev -virtual ----------" >> vio.cfg
	/usr/ios/cli/ioscli lsdev -virtual > vio.cfg
	echo "\n\n------------ lspath ----------" >> vio.cfg
	/usr/ios/cli/ioscli lspath  >> vio.cfg
	echo "\n\n------------ lsmap ----------" >> vio.cfg
	/usr/ios/cli/ioscli lsmap -all >> vio.cfg
	
fi
}

do_ras()
{
if [ -f /usr/sbin/raso ]; then
	echo "\n\n------------ RAS   ----------\nraso -a" >> $CFGOUT
	raso -a >> $CFGOUT
fi
if [ -f /usr/sbin/errctrl ]; then
	echo "\nerrctrl -q" >> $CFGOUT
	errctrl -q >> $CFGOUT
fi
if [ -f /usr/sbin/ctctrl ]; then
	echo "\nctctrl -q" >> $CFGOUT
	ctctrl -q >> $CFGOUT
fi

}

do_fc()
{
FCSTATOUT=fcstat.out
if [ -f /usr/sbin/fcstat ]; then
	echo "\n\n------------ FCSTAT   > fcstat.out ----------\n" >> $CFGOUT
	echo "\n\n------------ FCSTAT    ----------\n" > $FCSTATOUT
	for f in `lsdev -Ccadapter|grep "^fcs"|awk '{print $1}'`; do
	echo "\n------------------------------------------------" >> $FCSTATOUT
		fcstat $f >> $FCSTATOUT
	done
fi
}
	

cp_odm()
{
	do_timestamp "copying ODM files"
        mkdir objrepos
        cp /etc/objrepos/* objrepos
        #do_odm $PWD/objrepos
}
do_xmwlm()
{
	cp /etc/perf/daily/* .
}

do_detailed_mem()
{
if [ "$detailed_mem_flag" = 1 ]; then
	do_timestamp "memdetils.sh  $user_threshold_flag"
	mkdir mem_details_dir ;  cd mem_details_dir
	$PERFPMRDIR/memdetails.sh $user_threshold_flag > memdetails.out
	cd ..
fi
}

do_config_begin
cp_odm
do_uname
do_mem
do_kdb_swpft
do_lsps
do_ipcs
if [ "$quicker_cfg" != 1 ]; then
	do_lsdev
	#do_lspv
	#do_lspv_l
	do_lspv_new
	do_lsvg
	do_lsvg_l
	do_lslv
	do_ssa
	do_lsattr
fi
do_fastt
do_mount
do_lsfs
do_df
#do_quicksnap
do_netstat
do_ifconfig
do_no
do_nfso
do_showmount
do_cp_tunables
do_tunables_FL
do_tunables_x
do_schedo
do_vmo_vmstat_v
do_lvmo
do_ras
do_mempool
do_jfs2mem
do_jfs2stats
do_wlm
do_genkld
do_genkex
do_audit
do_env
do_getevars
do_errpt
do_ifix_list
do_lslpp
do_instfix
do_java
do_lsslot
do_lscfg_vp
do_lsc
do_kdb_xm
if [ "$quicker_cfg" != 1 ]; then
	#do_kdb_th
	do_kdb_vnode_vfs
fi
do_devtree
do_sysdumpdev
do_bosdebug
do_locktrace
do_unix
do_pmctrl
do_rset
do_gennames
do_crontab
do_limits
do_initt_fs_rc
do_what
do_vio
#do_fc    # moved to monitor.sh
do_xmwlm
do_detailed_mem
do_cfg_end
