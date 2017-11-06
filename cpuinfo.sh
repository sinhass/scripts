#!/bin/bash
# Siddhartha Sinha
#

echo -n "Enter the type of servers[Ex. cs, pd, sge]:"
read SERVERTYPE
echo "Please wait."
if [ -f /tmp/CPU_DATABASE ]; then
   rm /tmp/CPU_DATABASE
fi
  for COUNTS in "$SERVERTYPE"{1..200}
     do


       ping -c4 $COUNTS >/dev/null 2>&1

       if [[ $? -eq 0 ]];then
        echo $COUNTS: >>/tmp/$SERVERTYPE.CPU_DATABASE
        ssh -q $COUNTS  "dmidecode -t processor | egrep  -e 'Socket Designation' -e 'Version' -e 'Core Count' -e 'Thread Count'" >>/tmp/$SERVERTYPE.CPU_DATABASE
      fi
     done
echo "Completed"
