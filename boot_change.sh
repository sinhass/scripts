#!/bin/ksh
#set -xv
######################################################################
## boot_change.sh utility                                           ##
## Copyright (C) by EMC Corporation 2004 all rights reserved.       ##
## krichards V1.0.0.0  04/26/04                                     ## 
## muniep    V2.0.0.0  01/10/06                                     ##
######################################################################

######################################################################
LANG=C
ODMDIR=/etc/objrepos
export ODMDIR
RC=0
TYPE="SYMM"
SCSIDEV=`lsdev -Ct*SYMM* -F"name" -sscsi`
FCPDEV=`lsdev -Ct*SYMM* -F"name" -sfcp`
####################################
#                                  #
# Check for Symmetrix ODM fileset  #
#                                  #
####################################
lslpp -l EMC.Symmetrix.aix.rte > /dev/null 2>&1
if [ $? -eq 0 ]
then
#####################################
#                                   #
# Check for Symmetrix SCSI devices  #
#                                   #
#####################################
	for i in $SCSIDEV; do
	odmget -q "name=$i" CuDv | grep $TYPE > /dev/null 2>&1 || RC=1
 	if [[ ${RC} -eq 0 ]]
 	then
 	print "SYMMETRIX SCSI device $i was converted to Other SCSI Disk Drive"
	odmchange -o CuDv -q name=$i ./osscsidisk.add
 	fi
	RC=0
	done
#####################################
#                                   #
# Check for Symmetrix FCP devices   #
#                                   #
#####################################
        for i in $FCPDEV; do
        odmget -q "name=$i" CuDv | grep $TYPE > /dev/null 2>&1 || RC=1
        if [[ ${RC} -eq 0 ]]
        then
        print "SYMMETRIX FCP device $i was converted to Other FC SCSI Disk Drive"
        odmchange -o CuDv -q name=$i ./osfcpdisk.add
        fi
        RC=0
        done
else
print "
EMC.Symmetrix.aix.rte fileset is not installed"
fi
