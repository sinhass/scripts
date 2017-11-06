#!/bin/bash
# New Modified Backup script
# 05/18/2017
# - Sid
# local Backup only
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:

LOGFILE = /root/local_backuplog.log
MAIL_RECEPIENT = ssinha@barefootnetworks.com
ERROR_LOG = /tmp/local_dir_create_err
BACKUPLOG = /root/local_backups.log
MOUNT_STATUS = /tmp/local_mount_status.tmp
BACKUP_LOCK = /root/.local_backup_lock

START_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Start Date:$DATE" >>$BACKUPLOG
	echo "Start Time:$TIME" >>$BACKUPLOG
}

STOP_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Stop Date:$DATE" >>$BACKUPLOG
	echo "Stop Time:$TIME" >>$BACKUPLOG
}

SEND_UPDATE () {
  mailx -s 'Backup did not start'  $MAIL_RECEPIENT
}

SEND_NOTIFICATION () {
	mailx -s 'Urgent !! backupfs1 alert!!'  $MAIL_RECEPIENT
}

SEND_DIR_CREATE_ERROR() {
	cat $ERROR_LOG | SEND_NOTIFICATION
	exit 1
}

SEND_MOUNT_ERROR (){
	cat $ERROR_LOG | SEND_NOTIFICATION
	exit 1
}


CREATE_LOCAL_MOUNTS () {
	if [ ! -d "/mnt/pd_backups/pd6" ]; then
		mkdir /mnt/pd_backups
		mkdir -p /mnt/pd_backups/pd6 2>$ERROR_LOG
			if [ $? -ne 0 ];then
			 		SEND_DIR_CREATE_ERROR
			fi
	fi

	if [ ! -d "/mnt/pd_backups/pd16" ]; then
		mkdir -p /mnt/pd_backups/pd16 2>>$ERROR_LOG
			if [ $? -ne 0 ];then
			 	SEND_DIR_CREATE_ERROR
			fi
	fi

	if [ ! -d "/mnt/pd_backups/pd15" ]; then
		mkdir -p /mnt/pd_backups/pd15 2>$ERROR_LOG
		if [ $? -ne 0 ];then
			SEND_DIR_CREATE_ERROR
		fi
	fi
}


MOUNT_AND_CHECK_LOCAL_FOLDERS () {

	df -h | egrep /mnt/local_backups/pd6
	if [ $? -ne 0 ]; then
		mount -t nfs -o ro pd6.barefoot-int.lan:/local /mnt/pd_backups/pd6 2>$ERROR_LOG
		if [ $? -ne 0 ]; then
			SEND_MOUNT_ERROR
		fi
	fi

	df -h | egrep /mnt/local_backups/pd16
	if [ $? -ne 0 ]; then
		mount -t nfs -o ro pd16.barefoot-int.lan:/local /mnt/pd_backups/pd16  2>$ERROR_LOG
		if [ $? -ne 0 ]; then
			SEND_MOUNT_ERROR
		fi
	fi

	df -h | egrep /mnt/local_backups/pd15
	if [ $? -ne 0 ]; then
		mount -t nfs -o ro pd15.barefoot-int.lan:/local /mnt/pd_backups/pd15  2> $ERROR_LOG
		if [ $? -ne 0 ]; then
			SEND_MOUNT_ERROR
		fi
	fi


}

CHECK_LOCAL_MOUNTS () {

	mount -p | awk '{print $2}' | egrep '/mnt/local_mounts' | grep -v jails | grep local_mounts | sort -u >$MOUNT_STATUS
	diff /root/local_mounts.txt $MOUNT_STATUS
		if [ $? -ne 0 ]; then
			echo "Local  mounts are mismatched. local backups aborted !!!" | SEND_NOTIFICATION
			exit 1
		fi
}


#CHECK_FS2_RUNNING_BACKUPS () {
#
#	if [ -f /root/.fs2_backuplock ]; then
#		echo "FS2 Backup already in progress - Aborting" | SEND_UPDATE
#		exit 1
#	else
#		echo "Starting backup now.........."
#		touch /root/fs2_backuplog.txt
#	fi
#
#}

START_LOCAL_BACKUPS () {
	touch $BACKUP_LOCK

	START_DATE_TIME
	find /mnt/local_backups/pd6/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/pd6_local/ >> $BACKUPLOG

	if [ $? -ne 0 ]; then
 		echo "pd6 /local  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	else
		STOP_DATE_TIME
	 	echo "******************************************************">> $BACKUPLOG
 	fi


	find /mnt/local_backups/pd16/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/pd16_local/ >> $BACKUPLOG

	if [ $? -ne 0 ]; then
 		 echo "pd16 /local  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	else
		STOP_DATE_TIME
	 	echo "******************************************************">> $BACKUPLOG
 	fi


	find /mnt/local_backups/pd15/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/pd15_local/ >> $BACKUPLOG


	if [ $? -ne 0 ]; then
 		echo "pd15/local  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	else
		STOP_DATE_TIME
	 	echo "******************************************************">> BACKUPLOG
 	fi
}

FINAL_STATUS () {
mv $BACKUPLOG /root/backuplogs/$BACKUPLOG.$DATE
rm -f /root/.local_backuplogs
maix -s "Local Backups successful" | SEND_NOTIFICATION
}


CREATE_LOCAL_MOUNTS
MOUNT_AND_CHECK_LOCAL_FOLDERS
CHECK_LOCAL_MOUNTS
START_LOCAL_BACKUPS
if [ $? -eq 0 ]; then
	FINAL_STATUS
fi
