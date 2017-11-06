#!/bin/sh

#ssa_prog.sh
#Script created by Anthony Mancuso
#Edited last on 10/16/02 

echo "This script shows the progress of SSA disks currently being formatted"

for i in `lsdev -Cc pdisk -F name`
do
out=`ssa_progress -l $i`
echo $i "=" $out\%
done
