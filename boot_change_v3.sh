#!/bin/ksh
#set -x
######################################################################
## boot_change.sh utility                                           ##
## Copyright (C) by EMC Corporation 2004 all rights reserved.       ##
## krichards V1.0.0.0  04/26/04                                     ## 
## muniep    V2.0.0.0  01/10/06                                     ##
## kthomas chamc V3.0.0.0 08/28/09                                  ##
######################################################################

######################################################################
LANG=C
ODMDIR=/etc/objrepos
export ODMDIR
RC=0

###########################################
# Ask user to choose which ODM to replace #
###########################################

echo "Choose EMC ODM type to replace."
echo "Enter S for Symmetrix and C for Clariion. [S/C]"

read USER_INPUT

if [ "$USER_INPUT" = "S" ]
then

ODM_NAME=EMC.Symmetrix.aix.rte
SCSIDEV=`lsdev -Ct*SYMM* -F"name" -sscsi`
FCPDEV=`lsdev -Ct*SYMM* -F"name" -sfcp`
TYPE="SYMM"
DEVICE_TYPE="Symmetrix"

	else
	
	if [ "$USER_INPUT" = "C" ]
	then	
	ODM_NAME=EMC.CLARiiON.aix.rte
	FCPDEV=`lsdev -Ct*CLAR* -F"name" -sfcp`
	TYPE="CLAR"
	DEVICE_TYPE="Clariion"

		else
		echo "Input not valid. Exiting script."
		exit
	fi

fi

#Check for SYMM SCSI ODM
if [ "$SCSIDEV" = "" ]
then

	#Check for powerpath or mpio odm
	lslpp -l EMC.*.MPIO.rte > /dev/null 2>&1
	if [ $? -eq 0 ]
	then

		echo "MPIO filesets detected."
		CONVERTED_DEVICE="OTHER FC MPIO SCSI DISK DRIVE"
		INPUT_FILE=osfcpmpiodisk.add
		MPIO_TRUE=MPIO
	
		else
	
		lslpp -l EMC.*.fcp.rte > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			echo "Powerpath filesets detected."
			CONVERTED_DEVICE="OTHER FC SCSI DISK DRIVE"
			INPUT_FILE=osfcpdisk.add
			MPIO_TRUE=""
		
		else

			echo "No valid filesets detected. Exiting."
			exit
		fi
	fi

else
	#SYMM SCSI devices detected
	CONVERTED_DEVICE="OTHER SCSI DISK DRIVE"
	INPUT_FILE=osscsidisk.add	
fi

#Debug check for variables
echo ODM_NAME=$ODM_NAME
echo TYPE=$TYPE
echo DEVICE_TYPE=$DEVICE_TYPE
echo CONVERTED_DEVICE=$CONVERTED_DEVICE
echo INPUT_FILE=$INPUT_FILE
echo


####################################
#                                  #
# Check for type of ODM fileset    #
#                                  #
####################################
lslpp -l $ODM_NAME > /dev/null 2>&1

if [ $? -eq 0 ]
then

#####################################
#                                   #
# Convert Symmetrix SCSI devices    #
#                                   #
#####################################
	for i in $SCSIDEV; do
	odmget -q "name=$i" CuDv | grep $TYPE > /dev/null 2>&1 || RC=1
 	if [[ ${RC} -eq 0 ]]
 	then
 	print "$DEVICE_TYPE SCSI device $i was converted to $CONVERTED_DEVICE"
	odmchange -o CuDv -q name=$i ./$INPUT_FILE
 	fi
	RC=0
	done

#####################################################
#                                                   #
# Convert Symmetrix/CLARiiON FCP/MPIO FCP devices   #
#                                                   #
#####################################################
        for i in $FCPDEV; do
        odmget -q "name=$i" CuDv | grep $TYPE > /dev/null 2>&1 || RC=1
        if [[ ${RC} -eq 0 ]]
        then
        print "$DEVICE_TYPE FCP $MPIO_TRUE device $i was converted to $CONVERTED_DEVICE"
        odmchange -o CuDv -q name=$i ./$INPUT_FILE
        fi
        RC=0
        done

##############################################
#				             #
# Running savebase and bosboot               #
#                                            #	
##############################################
echo "Running savebase and bosboot. Please wait..."
savebase
bosboot -ad /dev/ipldevice

else
print "EMC ODM fileset is not installed." 
fi




