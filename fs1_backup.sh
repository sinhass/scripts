#!/bin/bash
# New Modified Backup script
# 03/10/2017
# - Sid
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:
parallels=/usr/local/bin/parallels

START_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Start Date:$DATE" >>/root/fs1_backuplog.txt
	echo "Start Time:$TIME" >>/root/fs1_backuplog.txt
}

STOP_DATE_TIME () {
	DATE=`date +%y-%m-%d`
	TIME=`date +%H:%M:%S`
	echo "Stop Date:$DATE" >>/root/fs1_backuplog.txt
	echo "Stop Time:$TIME" >>/root/fs1_backuplog.txt
}


SEND_NOTIFICATION () {
	mailx -s 'Urgent !! FS1 backupfs1 alert!!'  ssinha@barefootnetworks.com
}

SEND_UPDATE () {
	mailx -s 'Backup did not start'  ssinha@barefootnetworks.com
}

SEND_DIR_CREATE_ERROR() {

	cat /tmp/fs1_dir_create_err | SEND_NOTIFICATION
	exit 1
}

SEND_MOUNT_ERROR (){
	cat /tmp/mount_err | SEND_NOTIFICATION
	exit 1
}

CREATE_FS1_MOUNTS () {
	# Create only root level mount points.

	if [ ! -d  "/mnt/nessie/backups" ]; then
		mkdir /mnt/nessie
		mkdir /mnt/nessie/backups 2>/tmp/nessie_dir_create_err
		 if [ $? -ne 0 ];then
			SEND_DIR_CREATE_ERROR
		 fi
	 fi
	if [ ! -d  "/mnt/fs1" ]; then
		mkdir /mnt/fs1
	  mkdir  /mnt/fs1/backups 2>/tmp/fs1_dir_create_err
		 if [ $? -ne 0 ];then
			SEND_DIR_CREATE_ERROR
		 fi
   fi

	 if [ ! -d "/mnt/fs1/home" ]; then
	 	mkdir /mnt/fs1/home 2>>/tmp/fs1_dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/ip" ]; then
	 	mkdir  /mnt/fs1/ip 2>>/tmp/fs1_dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi


	 if [ ! -d "/mnt/fs1/jenkins" ]; then
	 	mkdir -p /mnt/fs1/jenkins 2>>/tmp/fs1_dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/proj" ]; then
	 	mkdir -p /mnt/fs1/proj 2>>/tmp/fs1_dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

	 if [ ! -d "/mnt/fs1/tools" ]; then
	 	mkdir -p /mnt/fs1/tools 2>>/tmp/fs1_dir_create_err
		if [ $? -ne 0 ];then
		 SEND_DIR_CREATE_ERROR
		fi
	 fi

}




MOUNT_AND_CHECK_FS1_NESSIE () {
    df -h | egrep /mnt/nessie/backups
			if [ $? -ne 0 ]; then
			  mount -t nfs -o ro nessie.barefoot-int.lan:/mnt/nessiepool/backups /mnt/nessie/backups 2>/tmp/mount_err
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
				mount -t nfs -o ro fs1.barefoot-int.lan:/mnt/fs1pool/tools /mnt/fs1/tools 2>/tmp/mount_err
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


CHECK_MOUNTS () {
	mount -p | awk '{print $2}' | egrep '/mnt/' | grep -v jails | grep fs1 | sort -u >/tmp/fs1_mount_status.txt

	diff /root/fs1_mount.txt /tmp/fs1_mount_status.txt
	if [ $? -ne 0 ]; then
		echo "Filer mounts are mismatched. Backup aborted !!!" | SEND_NOTIFICATION
		exit 1
	fi
}


CHECK_RUNNING_BACKUPS () {

	if [ -f /root/.fs1_backuplock ]; then
		echo "Backup already in progress - Aborting" | SEND_UPDATE
		exit 1
	else
		echo "Starting backup now.........."
		touch /root/fs1_backuplog.txt
	fi

}

CREATE_LOCAL_MOUNTS () {
mkdir -p /mnt/backuppool_sas/fs1_backups/proj/tofino
mkdir -p /mnt/backuppool_sas/fs1_backups/proj/tofino_b0
mkdir -p /mnt/backuppool_sas/fs1_backups/proj/jbay
mkdir -p /mnt/backuppool_sas/nessie_backups/backups
mkdir -p /mnt/backuppool_sas/fs1_backups/home
mkdir -p /mnt/backuppool_sas/fs1_backups/tools
mkdir -p /mnt/backuppool_sata/fs2_backups/proj3/tofino
mkdir -p /mnt/backuppool_sata/fs2_backups/proj2/tofino
mkdir -p /mnt/backuppool_sata/fs2_backups/proj2/tofino_icv



}

START_BACKUP () {
	touch /root/.fs1_backuplock
        echo "Starting FS1 Backup now."|mailx -s "FS1 Backup started" ssinha@barefootnetworks.com
	# FS1 proj and childs
	#
	# Just /proj/tofino
  START_DATE_TIME
	find /mnt/fs1/proj/tofino/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/proj/tofino/ >> /root/fs1_backuplog.txt
	 	if [ $? -ne 0 ]; then
	   	echo "FS1:/proj/tofino  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 	else
		 	STOP_DATE_TIME
		 	echo "******************************************************">> /root/fs1_backuplog.txt
	 	fi


	# Just /proj/tofino_b0
	START_DATE_TIME
	find /mnt/fs1/proj/tofino_b0/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/proj/tofino_b0/ >> /root/fs1_backuplog.txt
	 if [ $? -ne 0 ]; then
		 	echo "FS1:/proj/tofino_b0  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	 else
		 	STOP_DATE_TIME
  		echo "******************************************************">> /root/fs1_backuplog.txt
	 fi

	#Just /proj/jbay
	START_DATE_TIME
	find /mnt/fs1/proj/jbay/* \( ! -name . -prune \) -type d -print | parallel -v -j10 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/proj/jbay/ >> /root/fs1_backuplog.txt
 	 if [ $? -ne 0 ]; then
 			echo "FS1 /proj/jbay  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	 else
		 STOP_DATE_TIME
		 echo "******************************************************">> /root/fs1_backuplog.txt
 	 fi

	# Everything else of /proj
	START_DATE_TIME
	find /mnt/fs1/proj/ -maxdepth 1 \! \( -path "/mnt/fs1/proj/tofino" -or -path /mnt/fs1/proj/tofino_b0 -or -path /mnt/fs1/proj/ -or -path /mnt/fs1/proj/jbay \) | parallel -v -j8 rsync --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/proj/ >> /root/fs1_backuplog.txt
	 if [ $? -ne 0 ]; then
 		 echo "FS1 /proj  Backup failed!! Pls investigate." | SEND_NOTIFICATION
 	 else
		 STOP_DATE_TIME
	 	 echo "******************************************************">> /root/fs1_backuplog.txt

 	 fi


	 # /backups
	 START_DATE_TIME
	 find /mnt/nessie/backups/ -maxdepth 1 \! \( -path "/mnt/nessie_backups/backups/" \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/nessie_backups/backups/ >> /root/nessie_backuplog.txt
	  if [ $? -ne 0 ]; then
	 	 echo " /backups  Backup failed!! Pls investigate." | SEND_NOTIFICATION
	  else
	 	 STOP_DATE_TIME
	 	 echo "******************************************************">> /root/fs1_backuplog.txt

	  fi

		# /home
		START_DATE_TIME
		find /mnt/fs1/home/ -maxdepth 1 \! \( -path "/mnt/fs1/home/" \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/home/ >> /root/fs1_backuplog.txt
#		 if [ $? -ne 0 ]; then
#			echo "FS1 /home  Backup failed!! Pls investigate." | SEND_NOTIFICATION
#		 else
			STOP_DATE_TIME
			echo "******************************************************">> /root/fs1_backuplog.txt

#		 fi


		 # /tools
		  START_DATE_TIME
		  find /mnt/fs1/tools/ -maxdepth 1 \! \( -path "/mnt/fs1/tools/" \) | parallel -v -j8 rsync --delete --delete-excluded --exclude-from '/root/exclude-list.txt' -apvu {} /mnt/backuppool_sas/fs1_backups/tools/ >> /root/fs1_backuplog.txt
		  if [ $? -ne 0 ]; then
		 	echo "FS1 /tools  Backup failed!! Pls investigate." | SEND_NOTIFICATION
		  else
		 	STOP_DATE_TIME
		 	echo "******************************************************">> /root/fs1_backuplog.txt
			# DO NOT DELETE THESE LINES BELOW OR ADD NEW MOUNTS BELOW
		 	echo "Backup  successfully completed. Logfile is /root/backuplogs/fs1_backuplog.$DATE" | mailx -s "FS1: Backup completed" ssinha@barefootnetworks.com
		 	mv /root/fs1_backuplog.txt /root/backuplogs/fs1_backuplog.$DATE
		 	rm -f /root/.fs1_backuplock
		  fi


}

CHECK_RUNNING_BACKUPS
CREATE_FS1_MOUNTS
MOUNT_AND_CHECK_FS1_NESSIE
#CHECK_MOUNTS
CREATE_LOCAL_MOUNTS
START_BACKUP
