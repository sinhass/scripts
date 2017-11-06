#!/bin/bash
# Author: Siddhartha Sankar Sinha
# To update LDAP user alises from Google
#

#Global Variables

GMAIL_USER_LIST=/root/GMAIL/gmail_users.lst
USER_LIST=/root/GMAIL/users_list
LDIF_PATH=/root/GMAIL/LDIF
GMAIL_PATH=/root/GMAIL
USER_PATH=/root/GMAIL/USERS
HOSTNAME=$(hostname|sed -e 's/.pdlab.com//')

CHECK_SERVER () {

	if [ $HOSTNAME != bfsalt01 ];then
		echo " Please run this script from bfsalt01.pdlab.com server."
		exit 1
	fi

}

CHECK_DEPENDENCIES () {

    echo "Installing dependencies and necessary fils. Pls wait.."
    if [ ! -e /usr/bin/pcregrep ];
    	then 
    	yum install pcre-tools in linux -y >/dev/null 2>&1
    fi
    if [ ! -e /usr/bin/ldapsearch ];
    	then 
		yum install openldap-clients -y >/dev/null 2>&1
	fi 
}

CHECK_FOLDERS () {

	if [ -e /root/GMAIL/gmail_users.lst ]; then
		cat /dev/null >/root/GMAIL/gmail_users.lst
	else
		touch /root/GMAIL/gmail_users.lst
	fi

	if [ -e /root/GMAIL/users_list ]; then
		cat /dev/null >/root/GMAIL/users_list
	else
		touch /root/GMAIL/users_list
	fi

	if [ ! -d /root/GMAIL ]; then
		mkdir /root/GMAIL
	fi

	if [ -d /root/GMAIL/LDIF ]; then
		rm -rf /root/GMAIL/LDIF/*
	else
		mkdir /root/GMAIL/LDIF
	fi

	if [ -d /root/GMAIL/USERS ]; then
		rm -rf /root/GMAIL/USERS/*
	else
		mkdir /root/GMAIL/USERS
	fi

}

GET_USER_LIST () {
	cd $GMAIL_PATH

	# Get all Google User List from GAM
		echo "Getting users list from Google. Pls wait..."
		/root/bin/gam/gam print users>$GMAIL_PATH/gmail_users.lst
		sed -i.bk -e 's/\@barefootnetworks.com//g' -e '/primaryEmail/d' $GMAIL_PATH/gmail_users.lst

	# Now generating files for each users
		for USERS in `cat $GMAIL_PATH/gmail_users.lst`
			do /root/bin/gam/gam info user $USERS | egrep -e address -e User |sed -e 's/^User/mail/' -e 's/address/proxyAddresses/' \
			-e 's/^ //' |tee -a $USER_PATH/$USERS.gmail 
		done

	cd $LDIF_PATH

		#Colecting the existing proxy address and DN
		for USERS in `cat $GMAIL_PATH/gmail_users.lst`
			do
			ldapsearch -LLL -b "dc=corp,dc=barefootnetworks,dc=com" -D "Barefoot\ldap_bind" -x -w 'BareF0oT123$#' \ 
			-h 10.10.10.10 "(samaccountname=$USERS)" dn proxyaddresses | perl -p00e 's/\r?\n //g'| \
			grep -e ^dn -e ^proxy > $LDIF_PATH/$USERS.ldif

		# Pulling exiting LDAP Proxy Address to a tmp file
			grep proxy $USERS.ldif > $LDIF_PATH/$USERS.tmp

		# Collecting only non existant proxy address in LDAP
			grep -v -x -f $USERS.tmp $USER_PATH/$USERS.gmail>$LDIF_PATH/$USERS.add_these

		#  Now Delete the existing LDAP Proxy Line from the file so that it doesn't fail.
			sed -i.bk '/proxyAddresses/d' $LDIF_PATH/$USERS.ldif

		# Now add the new proxy address line to the ldif file

			cat $LDIF_PATH/$USERS.add_these |grep ^proxyAddresses >>$LDIF_PATH/$USERS.ldif
			sed -i.bk '/proxyAddresses/a -' $LDIF_PATH/$USERS.ldif
			sed -i.bk1 '/proxyAddresses/i changetype: modify\nadd: proxyAddresses' $LDIF_PATH/$USERS.ldif
			sed -i.bk2 's/modify /modify/' $LDIF_PATH/$USERS.ldif
			sed -i.bk3 '2!{/changetype/d;}' $LDIF_PATH/$USERS.ldif
			pcregrep -l -M  '^dn.*(\n|.)*proxy' *.ldif >final_list.lst
			
		done

}

UPDATE_LDAP_NOW () {

	for USERS in `cat $LDIF_PATH/final_list.lst`
	do
		ldapmodify -x -D "Barefoot\ldap_bind" -w 'BareF0oT123$#' -h 10.10.10.10 -f $LDIF_PATH/$USERS
	done
}

CHECK_SERVER
CHECK_DEPENDENCIES
CHECK_FOLDERS
GET_USER_LIST
echo "This is the final list of files to update ldap emails."
cat $LDIF_PATH/final_list.lst
UPDATE_LDAP_NOW



