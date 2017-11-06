#!/bin/ksh
# This file will produce and email information needed for documentation
# purposes for RISC POWER4 systems.
# Author: Nate Salazar, BCRS, Boulder, CO
# Email: natesala@us.ibm.com
############################################################################

#Network Information

MACHINE_INFO=`hostname`"\t"`uname -a | awk '{print $2}'`

for i in `lsdev -Cc adapter | grep ent | grep -v EtherChannel | awk '{print $1}'`
do
echo "`hostname` \t \t  $MACHINE_INFO\t`lscfg -vpl $i | egrep -i 'Specific|Hardware' | cut -c 37-50`\t`lscfg -vpl $i | grep Network | cut -c 37-49`\t$i" >> `hostname`_network.txt
done

for i in `lsdev -Cc adapter | grep fcs | awk '{print $1}'`
do
echo "`lscfg -vpl $i | grep Z8 | cut -c 45-52`\t`lscfg -vpl $i | grep Physical | cut -c 24-36`\t$i" >> `hostname`_zones.txt
done

echo "Enter email address to send docs to:\c "
_EMAIL=
read _EMAIL
HOSTNAME=`hostname`

if [ -r `hostname`_network.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_network.txt
quit
END_SCRIPT

rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_network $_EMAIL < ./"$HOSTNAME"_network.txt
rm `hostname`_network.txt
fi
if [ -r `hostname`_zones.txt ]
then
ftp -n 172.21.64.2 <<END_SCRIPT
quote USER ftp
quote PASS abc@xyz.com
cd /pub/docs
put `hostname`_zones.txt
quit
END_SCRIPT
rsh 172.21.64.2 -l docs mailx -s "$HOSTNAME"_zones $_EMAIL < ./"$HOSTNAME"_zones.txt
rm `hostname`_zones.txt
fi

