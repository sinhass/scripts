#!/bin/bash
# Author : Siddhartha S Sinha

blink=$(tput blink)
offblink=$(tput sgr0)
reverse=$(tput smso)
bold=$(tput bold)
offbold=$(tput rmso)
COLUMNS=80
LINES=24
#TERM=vt320
export COLUMNS LINES TERM

#
#
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


Pause()
{
        echo ""
        echo "Hit Enter to clear the Screen and Continue........"
        read
tput clear
}


READUSER() {
	echo -e "\033[1;31mThis script will create user id across all the servers. So be careful.\033[1;0m"
	echo -n "Please type a valid user (login) name you want to create. Use AD username without @email.com. Ex. john.doe  : "
	read USER_NAME
	USER_NAME="${USER_NAME,,}"
	echo -n "Please type Full Name or the full corporate email id :"
	read FULL_NAME
	if [[ -z ${USER_NAME} || -z $FULL_NAME ]]; then
	echo "You must type both username and Full Name of the user, per security policy."
	echo "Please rerun the program if you to continue."
        exit 1
        else
        {
	echo "The user name you type is $USER_NAME"
	echo "Username will always be converted to lower case."
  	if GetYesNo "Do you want to continue ? [y/n]"
       	then
	echo "Ok, I will create $USER_NAME."
	export USER_NAME="$USER_NAME"
	export FULL_NAME="$FULL_NAME"
	else
	echo "Ok, rerun the command if you want to continue"
	exit 1

        	fi
			}
	fi
	}


READPASS() {


	echo -n "Please enter the new password:"
	 unset newpass;
                while IFS= read -r -s -n1 newpass1; do
                if [[ -z $newpass1 ]]; then
                echo
                break
                else
                echo -n '*'
                newpass+=$newpass1
                fi
                done


	echo ""
	echo -n "Please verify the new password:"
                while IFS= read -r -s -n1 newpass2; do
                if [[ -z $newpass2 ]]; then
                echo
                break
                else
                echo -n '*'
                newpassNEW+=$newpass2
                fi
                done


	echo ""
	if [ $newpass == $newpassNEW ]; then
	{
	if GetYesNo "Do you want to continue ? [y/n]"
        then
	echo "OK, I will use that password."
		{
        		if [ -x /opt/rootpass/cryptpass ];then
        		HASH=`/opt/rootpass/cryptpass $newpass`
        		HASHRHLX='$1$82gUYyNV$VWb5dxPAOqMFo9ZMWqFEW1'
        		HASHRHLX=`echo "$HASH" | cut -f2 -d ":"`
        		HASHLINUX=`echo "$HASHRHLX" | perl -p -e 's#\\$#\\\\\\$#g'`
        		else
        		echo "Cannot find cryptpass. Install perl-Digest-MD5 and"
						echo "Download rootpass scripts from the link below"
						echo "https://www.novell.com/coolsolutions/tools/17386.html"
						echo "Modify them before you use. Donot use the rootpass script."
						echo "That is broken and that's why I wrote this script. "
						echo "Use cryptpass only from that tool."
        		exit 1
        		fi
		}
		else
		echo "Please start again"
		exit 1
		fi
	}
	else
	echo "Passwords don't match. Please start again."
	exit 1
	fi
	}
#
#
#
READMACHINE () {
 	echo -n 'Please enter the hostname you want to change: '
       	read machine
       	for i in $machine
       	do
       	ping -c2 $i > /dev/null 2>&1
       	if [ $? -eq 0 ]; then
          SERVEROS=`ssh -q -o StrictHostKeyChecking=no $i uname`
	    ssh -q $i "ls -l /usr/local/etc/sudoers"  >/dev/null 2>&1
            if [ $? -eq 0 ]; then
            SUDOPATH=/usr/local/etc/sudoers
            else
            SUDOPATH=/etc/sudoers
            fi

          {
	   if  [ $SERVEROS == Linux ];
            then
#
#
                ssh -q $i "useradd -m -c \"$FULL_NAME\" -s /bin/bash -d /home/$USER_NAME $USER_NAME && perl -p -i.bk -e  's#^$USER_NAME:.*?:#$USER_NAME:$HASHLINUX:#' /etc/shadow" >>/tmp/make_user_result 2>&1

		scp -q -rp .bashrc $i:/home/$USER_NAME/.bashrc && ssh -q $i "chown  $USER_NAME /home/$USER_NAME/.bashrc" >>/tmp/make_user_result 2>&1

		ssh -q $i "grep $USER_NAME /etc/ssh/sshd_config" >/dev/null 2>&1

			if [ $? -ne 0 ]; then

				echo "$USER_NAME" >/tmp/USER_NAME
				scp -rp -q /tmp/USER_NAME $i:/tmp
				ssh -q $i 'sed -i "/^AllowUsers/ s/$/ `cat /tmp/USER_NAME`/" /etc/ssh/sshd_config && /sbin/service sshd restart' >/dev/null 2>&1

			fi

		ssh -q $i "grep $USER_NAME $SUDOPATH" >/dev/null 2>&1

			if [ $? -ne 0 ]; then
			   ssh -q $i "perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1
			fi
#
# FOR SOLARIS SERVERS
#

                elif [ $SERVEROS == SunOS ];
		then
#		ssh -q $i "useradd -m -c \"$FULL_NAME\" -s /usr/bin/bash -d /export/home/$USER_NAME $USER_NAME && perl -p -i.bk -e  's#^$USER_NAME:.*?:#$USER_NAME:$HASHLINUX:#' /etc/shadow && perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >>/tmp/make_user_result 2>&1
		ssh -q $i "useradd -m -c \"$FULL_NAME\" -s /usr/bin/bash -d /export/home/$USER_NAME $USER_NAME && perl -p -i.bk -e  's#^$USER_NAME:.*?:#$USER_NAME:$HASHLINUX:#' /etc/shadow " >>/tmp/make_user_result 2>&1

		scp -q -rp  .profile_new $i:/export/home/$USER_NAME/.profile.new && ssh -q $i "cat /export/home/$USER_NAME/.profile.new >>/export/home/$USER_NAME/.profile" >>/tmp/make_user_result 2>&1

		ssh -q $i "grep  $USER_NAME  /etc/ssh/sshd_config" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then

			echo "$USER_NAME" >/tmp/USER_NAME
			scp -rp -q /tmp/USER_NAME $i:/tmp
			ssh -q $i 'sed -i "/^AllowUsers/ s/$/ `cat /tmp/USER_NAME`/" /etc/ssh/sshd_config && /usr/sbin/svcadm restart svc:/network/ssh:default' >/dev/null 2>&1

                        fi

			ssh -q $i "grep $USER_NAME $SUDOPATH" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then
                           ssh -q $i "perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1
                        fi


	     else
                  echo "OS not supported"
	     fi
			}
		else
		 echo "Unable to reach $i"
		 fi
			done

		}


READLIST () {
echo -n "Please enter the full path of the Server List File : "
      read machine
for i in `cat $machine`
     do
     ping -c2 $i > /dev/null 2>&1
     if [ $? -eq 0 ]; then
     SERVEROS=`ssh -q $i uname`
	    ssh -q $i "ls -l /usr/local/etc/sudoers"  >/dev/null 2>&1
            if [ $? -eq 0 ]; then
            SUDOPATH=/usr/local/etc/sudoers
            else
            SUDOPATH=/etc/sudoers
            fi
	{
           if  [ $SERVEROS == Linux ];
            then
#
#
                ssh -q $i "useradd -m -c \"$FULL_NAME\" -s /bin/bash -d /home/$USER_NAME $USER_NAME && perl -p -i.bk -e  's#^$USER_NAME:.*?:#$USER_NAME:$HASHLINUX:#' /etc/shadow" >>/tmp/make_user_result 2>&1

                scp -q -rp .bashrc $i:/home/$USER_NAME/.bashrc && ssh -q $i "chown  $USER_NAME /home/$USER_NAME/.bashrc" >>/tmp/make_user_result 2>&1

                ssh -q $i "grep $USER_NAME /etc/ssh/sshd_config" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then

                                echo "$USER_NAME" >/tmp/USER_NAME
                                scp -rp -q /tmp/USER_NAME $i:/tmp
                                ssh -q $i 'sed -i "/^AllowUsers/ s/$/ `cat /tmp/USER_NAME`/" /etc/ssh/sshd_config && /sbin/service sshd restart' >/dev/null 2>&1

                        fi

                ssh -q $i "grep $USER_NAME $SUDOPATH" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then
                           ssh -q $i "perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1
                        fi

                elif [ $SERVEROS == SunOS ];
                then
                ssh -q $i "useradd -m -c \"$FULL_NAME\" -s /usr/bin/bash -d /export/home/$USER_NAME $USER_NAME && perl -p -i.bk -e  's#^$USER_NAME:.*?:#$USER_NAME:$HASHLINUX:#' /etc/shadow " >>/tmp/make_user_result 2>&1

                scp -q -rp  .profile_new $i:/export/home/$USER_NAME/.profile.new && ssh -q $i "cat /export/home/$USER_NAME/.profile.new >>/export/home/$USER_NAME/.profile" >>/tmp/make_user_result 2>&1

                ssh -q $i "grep  $USER_NAME  /etc/ssh/sshd_config" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then

                        echo "$USER_NAME" >/tmp/USER_NAME
                        scp -rp -q /tmp/USER_NAME $i:/tmp
                        ssh -q $i 'sed -i "/^AllowUsers/ s/$/ `cat /tmp/USER_NAME`/" /etc/ssh/sshd_config && /usr/sbin/svcadm restart svc:/network/ssh:default' >/dev/null 2>&1

                        fi

			ssh -q $i "grep $USER_NAME $SUDOPATH" >/dev/null 2>&1

                        if [ $? -ne 0 ]; then
                           ssh -q $i "perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1
                        fi


             else
                  echo "OS not supported"
             fi
                        }

                else
                 echo "Unable to reach $i"
                 fi
                        done
			}



MAIN_MENU () {

tput clear
echo "                            $blink$reverse USER CREATE MAIN MENU$offblink$offbold"
echo "                                      $reverse  $offbold "
echo "        $reverse                                                               $offbold "
echo "        $reverse  $offbold 1.   CREATE USER IN ONE HOST                              $reverse  $offbold"
echo "        $reverse  $offbold 2.   CREATE USER ON MULTIPLE HOST                         $reverse  $offbold"
echo "        $reverse  $offbold q.   Quit or CTRL+C any time to quit                      $reverse  $offbold"
echo "        $reverse  $offbold                                                           $reverse  $offbold"
echo "        $reverse                                                               $offbold "
echo "        $reverse  $offbold      Author: Siddhartha Sankar Sinha                      $reverse  $offbold"
echo "        $reverse                                                               $offbold "
echo -n "               SELECT ONE OPTION :"
}

while :
do
MAIN_MENU
read SELECTION
case $SELECTION in
1) READUSER && READPASS && READMACHINE && Pause
;;
2) READUSER && READPASS && READLIST && Pause
;;
Q|q) exit
;;
*)
tput clear
echo "\007\007\007\c"
echo "\nThis Choice doesn't exist. Pls choose one from Menu\n"
;;
esac
done

