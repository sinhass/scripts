#!/bin/ksh
# Name: quicksnap  Version: 1.0
# Ian MacQuarrie, 408-256-1820
# IBM Product Engineering, SanJose CA
# Script used to collect host configuration data
# External commands: odmget,lsdev,lscfg,lsattr,lsvg,lslv,lslpp
# Creation Date: 06-07-04  

# Collect host info
print "Data collected for host" $(hostname) "on" $(date)
printf "\n"

# Collect some code levels
lslpp -L |grep -i "sdd"
lslpp -L |grep -i "ibm2105"
lslpp -L |grep -i "lvm"
lslpp -L |grep -i "df100"
printf "\n" 

# Collect the AIX maintenance level
instfix -i |grep ML
printf "\n"

# Collect info on FC adapters
print "HBA-FC     WWPN                 LOCATION"
fcs_list=`lsdev -Cc adapter |grep fcs |awk '{print $1}'`
for fcs in $fcs_list
 do
  wwpn=`lscfg -vl $fcs |grep Network |cut -c37-54`
  adap_loc=`lsdev -Cl $fcs |awk '{print $3}'`
  printf "%-10s %-20s %-10s\n" $fcs $wwpn $adap_loc
 done

# Collect into on SCSI adapters
printf "\n"
print "HBA-SCSI   LOCATION"
scsi_list=`lsdev -Cc adapter |grep scsi |awk '{print $1}'`
for scsi in $scsi_list
 do
  adap_loc=`lsdev -Cl $scsi |awk '{print $3}'`
  printf "%-10s %-20s\n" $scsi $adap_loc
 done

# Get a list of volume groups
vg_list=`odmget -q attribute=vgserial_id CuAt |grep name |cut -f2 -d\"`
for vg in $vg_list
 do
 if [ "$vg" != "rootvg" ]
 then
  lsvg -o |grep $vg > /dev/null 2>&1
  rc=$? 
  if [ $rc -eq 0 ] 
   then
    pp_size=`lsvg $vg |grep "PP SIZE" |awk '{print $6}'`
    print "\n"
    printf "VOLUME GROUP:%s  PP SIZE:%sM\n" $vg $pp_size 
    print "==================================================================="
    pvid_list=`odmget -q "name=$vg and attribute=pv" CuAt |grep value |cut -f2 -d\"`
    print "PV            MAJ/MIN   SERIAL#    PVID               LOCATION PATH"
    for pvid in $pvid_list
     do
      pvid_short=`print $pvid |cut -c1-16`
      disk_list=`odmget -q "value=$pvid and attribute=pvid" CuAt |grep name |cut -f2 -d\"`
    for disk in $disk_list
     do
      odmget -q name=$disk CuDv |grep 2105 > /dev/null
      Type2105=$?
      parent=`lsdev -Cl $disk -r parent`
       if [ "$parent" = "dpo" ] # collect data for vpath devices
        then
         major=`odmget -q value3=$disk CuDvDr |grep value1 |cut -f2 -d\"`
         minor=`odmget -q value3=$disk CuDvDr |grep value2 |cut -f2 -d\"`
         printf "%-12s %3x/%-17x %-10s\n"  $disk $major $minor $pvid_short                      
         hdisk_list=`odmget -q "name=$disk and attribute=active_hdisk" CuAt|grep value|cut -f2 -d\"|cut -f1 -d\/`
         for hdisk in $hdisk_list # collect data for hdisks under vpaths
         do
          serial=`lscfg -vl $hdisk |grep Serial |cut -c37-44`
          if [ $Type2105 -eq 0 ]
            then
             port_id=`lscfg -vl $hdisk |grep Z1 |cut -c37-40`
            else
             port_id="N/A"
          fi
          adap_loc=`lsdev -Cl hdisk6 |awk '{ print $3 }'`
          major=`odmget -q value3=$hdisk CuDvDr |grep value1 |cut -f2 -d\"`   
          minor=`odmget -q value3=$hdisk CuDvDr |grep value2 |cut -f2 -d\"`   
          printf "  %-10s %3x/%-6x %-29s %-8s %-10s\n" $hdisk $major $minor $serial $adap_loc $port_id 
         done
       else # collect data for non-vpath devices
          serial=`lscfg -vl $disk |grep Serial |cut -c37-44`
          if [ -z "$serial" ]
            then
              serial="N/A"
          fi
          if [ $Type2105 -eq 0 ]
            then
             port_id=`lscfg -vl $hdisk |grep Z1 |cut -c37-40`
            else
             port_id="N/A"
          fi
          adap_loc=`lsdev -Cl hdisk6 |awk '{ print $3 }'`
          major=`odmget -q value3=$disk CuDvDr |grep value1 |cut -f2 -d\"`   
          minor=`odmget -q value3=$disk CuDvDr |grep value2 |cut -f2 -d\"`   
          printf "%-12s %3x/%-6x %-10s %-18s %-6s %-10s\n" $disk $major $minor $serial $pvid_short $adap_loc $port_id
       fi
     done
    done
  # collect data for locical volumes
  vg_id=`odmget -q "name=$vg and attribute=vgserial_id" CuAt |grep value |cut -f2 -d\"`
  lv_id_list=`odmget -q "value like $vg_id.*" CuAt |grep value |cut -f2 -d\"`
  for lv_id in $lv_id_list
   do
    lv=`odmget -q "attribute=lvserial_id AND value=$lv_id" CuAt |grep name |cut -f2 -d\"`
    mount=`odmget -q "name=$lv and attribute=label" CuAt |grep value |cut -f2 -d\"`
    if [ -z "$mount" ]
      then mount="N/A"
    fi
    major=`odmget -q value3=$lv CuDvDr |grep value1 |cut -f2 -d\"`    
    minor=`odmget -q value3=$lv CuDvDr |grep value2 |cut -f2 -d\"`    
    pp_count=`lsvg -l $vg |grep $lv |awk '{print $4}'` 
    printf "\n"
    printf "LOGICAL VOLUME:%s MAJ/MIN:%x/%x MOUNT POINT:%s PPs:%s\n" $lv $major $minor $mount $pp_count
    copies=`lslv $lv |grep COPIES |awk '{print $2}'`
    if [ $copies -gt 1 ]
      then
       print "*** Mirrored LV ***"
       print "partition table saved to $lv.ppmap.out"   
       lslv -m $lv > $lv.ppmap.out
    fi
    pv_list=`lslv -l $lv |egrep "hdisk|vpath" |awk '{print $1}'`
    for pv in $pv_list
    do   
     pp_count=`lslv -l $lv |grep $pv |awk '{print $2}' |cut -f1 -d:`
     printf "%-10s %-10s\n" $pv $pp_count
    done
   done
  else
   printf "\n"
   print "$vg not online - can't collect data for offline volume groups."
  fi # end of if vg online
 fi # end of if not rootvg
 done
