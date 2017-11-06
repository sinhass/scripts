#!/bin/bash
# New Modified Backup script
# 03/10/2017
# - Sid
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:


START_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Start Date:$DATE" >>/root/backuplog.txt
	echo "Start Time:$TIME" >>/root/backuplog.txt
}

STOP_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Stop Date:$DATE" >>/root/backuplog.txt
	echo "Stop Time:$TIME" >>/root/backuplog.txt
}


SEND_NOTIFICATION () {

	mailx -s 'Urgent !! backupfs1 alert!!'  italerts@barefootnetworks.com

}

SEND_DIR_CREATE_ERROR() {

	cat /tmp/dir_create_err | SEND_NOTIFICATION
	exit 1
}

SEND_MOUNT_ERROR (){
	cat /tmp/mount_err | SEND_NOTIFICATION
	exit 1
}

CREATE_FS1_MOUNTS () {
	# Create only root level mount points.

	if [ ! -d  "/mnt/fs1/backups" ]; then
		mkdir /mnt/fs1
	  mkdir  /mnt/fs1/backups 2>/tmp/dir_create_err
		 if [ $? -ne 0 ];then
			SEND_DIR_CREATE_ERROR
		 fi
   fi

	 if [ ! -d "/mnt/fs1/home" ]; then
	 	mkdir /mnt/fs1/home 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/ip" ]; then
	 	mkdir  /mnt/fs1/ip 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi


	 if [ ! -d "/mnt/fs1/jenkins" ]; then
	 	mkdir -p /mnt/fs1/jenkins 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/proj" ]; then
	 	mkdir -p /mnt/fs1/proj 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/tools" ]; then
	 	mkdir -p /mnt/fs1/tools 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

}

CREATE_FS2_MOUNTS () {

	 if [ ! -d "/mnt/fs2/proj2" ]; then
		mkdir /mnt/fs2
	 	mkdir -p /mnt/fs2/proj2 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi



	 if [ ! -d "/mnt/fs2/proj3" ]; then
	 	mkdir -p /mnt/fs2/proj3 2>/tmp/dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi
 }


MOUNT_AND_CHECK_FS1 () {
    df -h | egrep /mnt/fs1/backups
			if [ $? -ne 0 ]; then
			  mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/backups /mnt/fs1/backups 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi
		df -h | egrep /mnt/fs1/home
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/home /mnt/fs1/home 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi
		df -h | egrep /mnt/fs1/tools
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/tools /mnt/fs1/tools2 >/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi

			df -h | egrep /mnt/fs1/ip
			  if [ $? -ne 0 ]; then
	    		mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/ip /mnt/fs1/ip 2>/tmp/mount_err
					if [ $? -ne 0 ]; then
						SEND_MOUNT_ERROR
					fi
				fi
		df -h | egrep /mnt/fs1/ip/tofino/chip
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/ip_tofino_chip /mnt/fs1/ip/tofino/chip 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi
		df -h | egrep /mnt/fs1/jenkins
		  if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/jenkins /mnt/fs1/jenkins 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi

		df -h | egrep /mnt/fs1/ip/mem
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/ip/mem /mnt/fs1/ip/mem 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi

	  df -h | egrep /mnt/fs1/proj
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/proj /mnt/fs1/proj 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi
		df -h | egrep /mnt/fs1/proj/jbay
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/proj/jbay /mnt/fs1/proj/jbay 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
			fi

		df -h | egrep /mnt/fs1/proj/tofino_b0
			if [ $? -ne 0 ]; then
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/proj/tofino_b0 /mnt/fs1/proj/tofino_b0 2>/tmp/mount_err
				if [ $? -ne 0 ]; then
					SEND_MOUNT_ERROR
				fi
	    fi


	}

MOUNT_AND_CHECK_FS2 () {

	 df -h | egrep /mnt/fs2/proj2
	 	if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2 /mnt/fs2/proj2  2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

	 df -h | egrep /mnt/fs2/proj2/tofino
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2/tofino /mnt/fs2/proj2/tofino 2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

	df -h | egrep /mnt/fs2/proj2/tofino_icv
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool/proj2/tofino_icv /mnt/fs2/proj2/tofino_icv 2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

	df -h | egrep /mnt/fs2/proj3
		if [ $? -ne 0 ]; then
		 	mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/proj3 /mnt/fs2/proj3 2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

  df -h | grep /mnt/fs2/proj3/tofino
		if [ $? -ne 0 ]; then
	   	mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/proj3/tofino /mnt/fs2/proj3/tofino 2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

  df -h | grep /mnt/fs2/proj3/trestles
		if [ $? -ne 0 ]; then
			mount -t nfs -o ro fs2.barefoot-int.lan:/mnt/fs2pool6tb/trestles /mnt/fs1/proj/trestles 2>/tmp/mount_err
			if [ $? -ne 0 ]; then
				SEND_MOUNT_ERROR
			fi
		fi

}

CHECK_MOUNTS () {
	mount -p | awk '{print $2}' | egrep '/mnt/' | grep -v jails | sort -u >/tmp/mount_status.tmp

	diff /root/fs_mount.txt /tmp/mount_status.tmp
	if [ $? -ne 0 ]; then
		echo "Filer mounts are mismatched. Backup aborted !!!" | SEND_NOTIFICATION
		exit 1
	fi
}


CHECK_RUNNING_BACKUPS () {

	if [ -f /root/.backuplock ]; then
		echo "Backup already in progress - Aborting"
		exit 1
	else
		echo "Starting backup now.........."
		touch /root/backuplog.txt
	fi

}

START_BACKUP () {
	touch /root/.backuplock

	# FS1 proj and childs
	#
	# Just /proj/tofino
  START_DATE_TIME
	find /mnt/fs1/proj/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj/tofino/ >> /root/backuplog.txt
	 if [ $? -ne 0 ]; then
	   echo "FS1 /proj/tofino  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
	    date >> /root/backuplog.txt
	 fi
  STOP_DATE_TIME
	echo "******************************************************">> /root/backuplog.txt

	# Just /proj/tofino_b0
  START_DATE_TIME
	find /mnt/fs1/proj/tofino_b0/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj/tofino_b0/ >> /root/backuplog.txt
	 if [ $? -ne 0 ]; then
		 echo "FS1 /proj/tofino_b0  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
		 date >> /root/backuplog.txt
	 fi
	 STOP_DATE_TIME
 	echo "******************************************************">> /root/backuplog.txt

  #Just /proj/jbay
  START_DATE_TIME
	 find /mnt/fs1/proj/jbay/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj/jbay/ >> /root/backuplog.txt
 	  if [ $? -ne 0 ]; then
 		 echo "FS1 /proj/jbay  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	  else
 		 date >> /root/backuplog.txt
 	  fi
		STOP_DATE_TIME
  	echo "******************************************************">> /root/backuplog.txt

   # Everything else of /proj
	 START_DATE_TIME
	 find /mnt/fs1/proj/ -maxdepth 1 \! \( -path "/mnt/fs1/proj/tofino" -or -path /mnt/fs1/proj/tofino_b0 -or -path /mnt/fs1/proj/ -or -path /mnt/fs1/proj/jbay \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj/ >> /root/backuplog.txt
	  if [ $? -ne 0 ]; then
 		 echo "FS1 /proj  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	  else
 		 date >> /root/backuplog.txt
 	 fi
	 STOP_DATE_TIME
 	 echo "******************************************************">> /root/backuplog.txt

   # FS2 backups
	 # /fs2/proj2/tofino
	 START_DATE_TIME
	 find /mnt/fs2/proj2/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj2/ >> /root/backuplog.txt

	 if [ $? -ne 0 ]; then
 		 echo "FS2 /proj2/tofino  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	 else
 		 date >> /root/backuplog.txt
 	 fi
	 STOP_DATE_TIME
 	 echo "******************************************************">> /root/backuplog.txt

   # /fs2/proj3/tofino
	 START_DATE_TIME
   find /mnt/fs2/proj3/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj2/ >> /root/backuplog.txt
	 if [ $? -ne 0 ]; then
	 	echo "FS2 /proj3/tofino  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
	   date >> /root/backuplog.txt
	 fi
	 STOP_DATE_TIME
 	 echo "******************************************************">> /root/backuplog.txt


	 # fs2/proj2/tofino_icv
   START_DATE_TIME
	 find /mnt/fs2/proj2/tofino_icv/* -maxdepth 1 \! \( -path /mnt/fs2/proj3/tofino/ \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool/backups/bigfoot/proj/ >> /root/backuplog.txt
	 if [ $? -ne 0 ]; then
	 	echo "FS2 /proj2/tofino_icv  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
	  date >> /root/backuplog.txt
	 fi
	 STOP_DATE_TIME
 	 echo "******************************************************">> /root/backuplog.txt

	 # Wrapping up
	 date >> /root/backuplog.txt
	 mv /root/backuplog.txt /root/backuplogs/backuplog.$DATE

	 rm -f /root/.backuplock
}

CHECK_RUNNING_BACKUPS && \
CREATE_FS1_MOUNTS && \
CREATE_FS2_MOUNTS && \
MOUNT_AND_CHECK_FS1 && \
MOUNT_AND_CHECK_FS2 && \
CHECK_MOUNTS && \
START_BACKUP


if [ $? -eq 0 ]; then
	echo "Backup  successfully completed. Logfile is /root/backuplogs/backuplog.$DATE" | mailx -s "Backup completed" italerts@barefootnetworks.com
else
	echo "Backup failed !!" | SEND_NOTIFICATION
fi
