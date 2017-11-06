#!/usr/bin/env bash

#!/bin/bash
# date: 01/13/2017
# Author: Siddhartha S Sinha
#echo "This script will create the Unix, vpn and WiFi accounts and passwords"
PATH=$PATH:/usr/bin:/usr/local/bin:/usr/sbin
#
# Check the argunemnt and Usage information

Usage () {
if [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
    echo "Usage: `basename $0` [OPTION] -f Firstname -l Lastname

Create Unix/VPN/Wifi user accounts and setup initial password.

Mandatory arguments.
  -a --auto		will create user name & password based on user name and availability.
  -m  --manual		select your own username (based on availability) & password.

Examples:
addnewuser -a -f John -l Doe
- Above command will try to create username jdoe if available, if user name is not
available then it will create username johnd, if not available then will try
to create doej, if not then it will create user id johndoe

adduser -m -f John -l Doe
- Above command will ask you to type user name and password. If username exists it will
  exit and you need to rerun the command again with new user name.

"
    exit 0
fi

if [ "$#" -eq 0 ]; then

echo "Type `basename $0` -h for help."

exit 0

fi
}
# This function will provide yes or no
GetYesNo()	{
	_ANSWER=
	if  [ $# -eq 0 ]; then
	echo "Usage: GetYesNo message" 1>&2
	exit 1
	fi

while :
do
	if [ "`echo -n`" = "-n" ]; then
		echo "$@\c"
		else
			echo -n "$@"
	fi

	read _ANSWER
	case "$_ANSWER" in
		[yY] | yes | YES | Yes)		return 0 ;;
		[nN] | no  | NO  | No )		return 1 ;;
		* ) echo "Please Enter y or n."		 ;;
	esac
     tput clear
done
}


# Collect Username and find the next available id
GETUSER_NAME () {
	HIGHEST_UID=$(getent passwd | awk -F ":" '{print $3}' | grep -v 65534 |  sort -n | tail -1)
	NEW_UID=$(($HIGHEST_UID + 1))
	echo -n "Enter First Name(Middle name/initial will be discarded):"
	read FIRST_NAME
        FIRST_NAME=$(echo "${FIRST_NAME,,}"|cut -d' ' -f1)
	echo -n "Enter Last Name:"
	read LAST_NAME
	LAST_NAME=$(echo "${LAST_NAME,,}"|cut -d ' ' -f2)
        USER_NAME=${FIRST_NAME:0:1}${LAST_NAME}
        getent passwd|awk -F":" '{print $1}'|grep ${USER_NAME}
        if [ $? -eq 0 ];then
           echo "User Name ${USER_NAME} is not available for use."
           echo "Will try to check with firstname now."
	    USER_NAME="${FIRST_NAME}${LAST_NAME:0:1}"
		getent passwd|awk -F":" '{print $1}'|grep ${USER_NAME}
                if [ $? -eq 0 ];then
                   echo " ${USER_NAME} also not available. Let me try last name and first initial."
                   USER_NAME=${LAST_NAME}${FIRST_NAME:0:1}
		   getent passwd|awk -F":" '{print $1}'|grep ${USER_NAME}
		    if [ $? -eq 0 ];then
                      echo "That is not available either. So I will select."
                      USER_NAME=${FIRST_NAME:0:4}${LAST_NAME:0:4}
                      getent passwd|awk -F":" '{print $1}'|grep ${USER_NAME}
                       if [ $? -eq 0 ];then
                         echo "I gave up. Please select the user name manually
       			 exit 0
                       fi
		    fi
		fi
        fi
    }
#        PASS_WORD=$(pwgen 10 -y 1)

# Create automatic password
CREATE_AUTOMATIC_PASSWORD () {

   chars='!%_+='
   { </dev/urandom LC_ALL=C grep -ao '[A-Za-z0-9]'  | head -n$((RANDOM % 8 + 4))
      echo ${chars:$((RANDOM % ${#chars})):1}   # Random special char.
    } | shuf | tr -d '\n'

   }


PASS_WORD=$(CREATE_PASSWORD)


echo "New User Name:${USER_NAME} and UID:${NEW_UID} Password:${PASS_WORD}"

CREATE_LDAP_USER() {
		echo "Now I will create Unix and openvpn  account with this information."
                smbldap-groupadd -g ${NEW_UID} ${USER_NAME}
                smbldap-useradd -N ${FIRST_NAME} -S ${LAST_NAME} -c "${FIRST_NAME} ${LAST_NAME}" -u ${NEW_UID} -g ${NEW_UID}
                \-G hw -m ${USER_NAME} -M "${FIRST_NAME}.${LAST_NAME}@barefoot.networks.com" -p '${PASS_WORD}'

}

"

RADIUS SETUP ----

$password = $_POST["pass1"];
	$username = $_POST["name"];
	$encryptpass = rtrim(shell_exec("/usr/bin/smbencrypt $password | /bin/awk {'print $2'}"));

	$newstring = "$username\t\tNT-Password := \"$encryptpass\"\n";
	#if( strpos(file_get_contents("/etc/raddb/users"),$username) === false ) {
	if( !preg_match("/\\b${username}\\b/", file_get_contents("/etc/raddb/users"))) {
		if(file_put_contents("/etc/raddb/users",$newstring, FILE_APPEND | LOCK_EX)) {
			shell_exec("/usr/bin/sudo /sbin/service radiusd reload");
			print "Successfully created password - please use your new credentials to login to SSID BarefootSecureWiFi";
		} else { print "Process is busy - please try again in a few seconds";}
	} else { print "Username is already present - please email ssinha@barefootnetworks.com if you forgot your password<br>";}

"
