#!/bin/bash
# Author Siddhartha Sankar Sinha.
#
# Sync LDAP emails to google email
#
# Global Variables
GMAIL_USER_LIST=/root/LDAP/gmail_users.lst
LDAP_USER_LIST=/root/LDAP/ldap_users.lst
LDIF_PATH=/root/LDAP/LDIF
GMAIL_PATH=/root/LDAP
USER_PATH=/root/LDAP/USERS
HOSTNAME=$(hostname|sed -e 's/.pdlab.com//')
DATE=$(date +%m%d%y)
ADMIN=ssinha@barefootnetworks.com


CHECK_FILE_FOLDERS () {

	if [ ! -e /root/LDAP/LDIF ]; then
		mkdir -p /root/LDAP/LDIF
	else
		rm -rf /root/LDAP/LDIF/*
	fi

	if [ ! -e /root/LDAP/USERS ]; then
		mkdir -p /root/LDAP/USERS
	else
		rm -rf /root/LDAP/USERS/*
	fi

}


GET_LDAP_EMAIL_ALISES() {

# Collecting all information
#
# Collect the USER Name from LDAP. Remove Service accounts.
ldapsearch -LLL -b "dc=corp,dc=barefootnetworks,dc=com" -D "Barefoot\ldap_bind" -x -w 'BareF0oT123$#'  -h 10.10.10.10 "(samaccountname=*)" dn proxyaddresses samaccountname | perl -p00e 's/\r?\n //g' | grep -v refldap | grep 'sAMAccountName: [a-z]' | egrep -v 'ssinha-admin|iiurchenko-admin|rwildgrube-admin|wifi|sc1|services|ldap_bind|keyscan|krbtgt' | awk '{print $NF}'>$USER_PATH/ldap_users.lst

# Now generate individual files for each user.
#
for USER_NAME in `cat $USER_PATH/ldap_users.lst`
do
	ldapsearch -LLL -b dc=corp,dc=barefootnetworks,dc=com -D 'Barefoot\ldap_bind' -x -w 'BareF0oT123$#' -h 10.10.10.10 "(samaccountname=$USER_NAME)" mail proxyaddresses | perl -p00e 's/\r?\n //g'| sed -e '/refldap/d' -e '/^dn/d' -e '/^$/d' | sort  > $USER_PATH/$USER_NAME.ldap
done

}

GET_GMAIL_EMAIL_ALISES() {

for USER_NAME in `cat $USER_PATH/ldap_users.lst`
do
	gam info user $USER_NAME | egrep 'User|address'|sed -e 's/User/mail/' -e 's/^ address/proxyAddresses/g' | sort >$USER_PATH/$USER_NAME.google 
done

}

COLLET_NO_GMAIL_ACCOUNT () {

	echo "No Barefoot Email accounts for the following users. Investigate ...." > $GMAIL_PATH/no_gmail_account.html
	find . -size 0|sed -e 's/.\/USERS\///g' -e 's/.google//g'>> $GMAIL_PATH/no_gmail_account.html		

}

COLLECT_OTHER_ERRORS () {

	echo "Investigate the discrepencies listed below with the  attached fils." >> $GMAIL_PATH/no_gmail_account.html

	grep -v -x -f $GMAIL_PATH/no_gmail_account.html  $USER_PATH/ldap_users.lst >$USER_PATH/ldap_users.new

	for USER_NAME in `cat $USER_PATH/ldap_users.new`
		do	
 			diff -q $USER_PATH/$USER_NAME.* >>$GMAIL_PATH/discrepencies.html
 			diff -q $USER_PATH/$USER_NAME.* >> $GMAIL_PATH/no_gmail_account.html
		done

}


BACKUP_FILES () {

	cat $GMAIL_PATH/discrepencies.html| awk '{print $2}'|sed -e 's/.google/.*/g' >$GMAIL_PATH/backup_list
	tar -cvf $GMAIL_PATH/discrepency_list.tar $(cat backup_list)
}


SEND_REPORT () {

	mutt -e 'set content_type=text/html' -s "LDAP & GMAIL email/aliases mismatch report." -a $GMAIL_PATH/discrepency_list.tar -- $ADMIN  <$GMAIL_PATH/no_gmail_account.html

}

MAIN () {

CHECK_FILE_FOLDERS
GET_LDAP_EMAIL_ALISES
GET_GMAIL_EMAIL_ALISES
COLLET_NO_GMAIL_ACCOUNT
COLLECT_OTHER_ERRORS
BACKUP_FILES
SEND_REPORT
}

MAIN 

