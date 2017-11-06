#!/bin/bash
# New Modified Backup script
# 03/10/2017
# - Sid
# FS2 Backup only
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:

START_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Start Date:$DATE" >>/root/fs2_backuplog.txt
	echo "Start Time:$TIME" >>/root/fs2_backuplog.txt
}

STOP_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Stop Date:$DATE" >>/root/fs2_backuplog.txt
	echo "Stop Time:$TIME" >>/root/fs2_backuplog.txt
}

SEND_UPDATE () {
        mailx -s 'Backup did not start'  ssinha@barefootnetworks.com
}

SEND_NOTIFICATION () {
	mailx -s 'Urgent !! backupfs1 alert!!'  ssinha@barefootnetworks.com
}

SEND_DIR_CREATE_ERROR() {
	cat /tmp/fs2_dir_create_err | SEND_NOTIFICATION
	exit 1
}

SEND_MOUNT_ERROR (){
	cat /tmp/fs2_mount_err | SEND_NOTIFICATION
	exit 1
}


CREATE_FS2_MOUNTS () {
	 if [ ! -d "/mnt/fs2/proj2" ]; then
			mkdir /mnt/fs2
		 	mkdir -p /mnt/fs2/proj2 2>/tmp/fs2_dir_create_err
				if [ $? -ne 0 ];then
			 		SEND_DIR_CREATE_ERROR
				fi
		fi

		if [ ! -d "/mnt/fs2/proj3" ]; then
		 	mkdir -p /mnt/fs2/proj3 2>/tmp/fs2_dir_create_err
				if [ $? -ne 0 ];then
			 		SEND_DIR_CREATE_ERROR
				fi
		fi
	 }


MOUNT_AND_CHECK_FS2 () {

	df -h | egrep /mnt/fs2/proj2
	 if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2 /mnt/fs2/proj2  2>/tmp/fs2_mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
		fi

	df -h | egrep /mnt/fs2/proj2/tofino
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2/tofino /mnt/fs2/proj2/tofino 2>/tmp/fs2_mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
		fi

	df -h | egrep /mnt/fs2/proj2/tofino_icv
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2/tofino_icv /mnt/fs2/proj2/tofino_icv 2>/tmp/fs2_mount_err
			if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
			fi
		fi

	df -h | egrep /mnt/fs2/proj3
		if [ $? -ne 0 ]; then
		 	mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/proj3 /mnt/fs2/proj3 2>/tmp/fs2_mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
		fi

  df -h | grep /mnt/fs2/proj3/tofino
		if [ $? -ne 0 ]; then
	   	mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/proj3/tofino /mnt/fs2/proj3/tofino 2>/tmp/fs2_mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
		fi

  df -h | grep /mnt/fs1/proj/trestles
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/trestles /mnt/fs1/proj/trestles 2>/tmp/fs2_mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
		fi

}

CHECK_FS2_MOUNTS () {

	mount -p | awk '{print $2}' | egrep '/mnt/' | grep -v jails | grep fs2 | sort -u >/tmp/fs2_mount_status.tmp
	diff /root/fs2_mounts.txt /tmp/fs2_mount_status.tmp
		if [ $? -ne 0 ]; then
			echo "FS2  mounts are mismatched. FS2 Backup aborted !!!" | SEND_NOTIFICATION
			exit 1
		fi
}


CHECK_FS2_RUNNING_BACKUPS () {

	if [ -f /root/.fs2_backuplock ]; then
		echo "FS2 Backup already in progress - Aborting" | SEND_UPDATE
		exit 1
	else
		echo "Starting backup now.........."
		touch /root/fs2_backuplog.txt
	fi

}

START_FS2_BACKUP () {
	touch /root/.fs2_backuplock

	 # /fs2/proj3/tofino
	 START_DATE_TIME
	 find /mnt/fs2/proj3/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/fs2_backups/proj3/tofino/ >> /root/fs2_backuplog.txt

	 if [ $? -ne 0 ]; then
 		 echo "FS2 /proj3/tofino  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	 else
		 STOP_DATE_TIME
	 	 echo "******************************************************">> /root/fs2_backuplog.txt
 	 fi

   # /fs2/proj3/tofino
	 START_DATE_TIME
   find /mnt/fs2/proj2/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/fs2_backups/proj2/tofino/ >> /root/fs2_backuplog.txt

	 if [ $? -ne 0 ]; then
	 	echo "FS2 /proj2/tofino Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
		 STOP_DATE_TIME
	 	 echo "******************************************************">> /root/fs2_backuplog.txt
	 fi


	 # fs2/proj2/tofino_icv
   START_DATE_TIME
	 find /mnt/fs2/proj2/tofino_icv/* -maxdepth 1 \! \( -path /mnt/fs2/proj2/tofino/ \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sata/fs2_backups/proj2/tofino_icv/ >> /root/fs2_backuplog.txt

	 if [ $? -ne 0 ]; then
	 		echo "FS2 /proj2/tofino_icv  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
	  	STOP_DATE_TIME
    	echo "******************************************************">> /root/fs2_backuplog.txt
			echo "FS2 Backup  successfully completed. Logfile is /root/backuplogs/root/fs2_backuplog.$DATE" | mailx -s "FS2 Backup completed" ssinha@barefootnetworks.com
	 fi


	 # Wrapping up

	 		mv /root/fs2_backuplog.txt /root/backuplogs/fs2_backuplog.$DATE
	 		rm -f /root/.fs2_backuplock

}

CHECK_FS2_RUNNING_BACKUPS 
CREATE_FS2_MOUNTS 
MOUNT_AND_CHECK_FS2 
#CHECK_FS2_MOUNTS 
START_FS2_BACKUP
