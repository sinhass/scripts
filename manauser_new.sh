#!/bin/bash
# Author : Siddhartha S Sinha
# Rev 1.0
# Date: 01/28/2017
# Barefoot Networks
#
################################################################################
#                         ADD ALL GLOBAL VARIABLES HERE                        #
################################################################################
blink=$(tput blink)
offblink=$(tput sgr0)
reverse=$(tput smso)
bold=$(tput bold)
offbold=$(tput rmso)
COLUMNS=80
LINES=24
TERM=vt220
export COLUMNS LINES TERM
DATE=$(date +%m%d%y)
ADMIN=itsupport@barefootnetworks.com
ADMIN1=romi@barefootnetworks.com
P4COMMAND=/tools/perforce/2016.2/p4
P4ADMIN=ssinha
HRMAIL=rachel@barefootnetworks.com
RADSERVER=bfrad01.barefoot-int.lan
VPNSERVER=openvpn.barefoot-int.lan
RADIUSPATH=/etc/raddb/mods-config/files/authorize
VPNGROUP=/etc/group
RUNFROM=bfsalt01

mv /root/scripts/temparea/p4template /root/scripts/temparea/p4template.$DATE >/dev/null 2>&1


##########################################################################################
# MISC FUNCTIONS
##########################################################################################

Pause()         ##### PAUSE FUNCTION #####
{
  echo ""
  echo "Hit Enter to clear the screen and continue........"
  read
  tput clear
}

GetYesNo()	{     ###### YES OR NO FUNCTION #####
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


##########################################################################################
# UNIX ACCOUNT RELATED FUNCTIONS
##########################################################################################

GET_UID () {   ##### COLLECT NEXT AVAILABLE USER ID AND GROUP #####

  HIGHEST_UID=`getent passwd | awk -F ":" '{print $3}' | grep -v 65534 |  \
  sort -n | tail -1`
  NEW_UID=$(($HIGHEST_UID + 1))
  echo " Next available User ID=$NEW_UID"
  export NEW_UID
}

COLLECT_USER_NAME () {  ##### COLLECT NEW EMPLOYEE NAME #####

  echo -n "Enter First Name(Middle name/initial will be discarded):"
  read first_NAME
  first_NAME="$(echo $first_NAME | tr '[:upper:]' '[:lower:]')"
  first_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${first_NAME:0:1})${first_NAME:1}"
  export  first_NAME

  echo -n "Enter Last Name:"
  read last_NAME
  last_NAME="$(echo $last_NAME | tr '[:upper:]' '[:lower:]')"
  last_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${last_NAME:0:1})${last_NAME:1}"
  export last_NAME

  echo "FullName:       $first_NAME $last_NAME " >/root/scripts/temparea/p4template

  FIRST_NAME=$(echo "${first_NAME,,}"|cut -d' ' -f1)
  export FIRST_NAME
  LAST_NAME=$(echo "${last_NAME,,}"|cut -d ' ' -f2)
  export LAST_NAME
}

SELECT_GROUP () {  ##### SELCT HW/SW GROUP #####
  echo "Please select the group carefully and type exactly as below. For hardware type hw, "
  echo "for software type sw and for customer team type cust."
  echo -n "Type which group the user will be[hw/sw/cust]?:"
  read GROUP
  GROUP=$(echo "${GROUP,,}"|cut -d' ' -f1)
  export GROUP
  if [ $GROUP == hw ];then
    echo -n "Type the CT Machine Name:"
    read CT_MACHINE
    export CT_MACHINE
  fi
}

SELECT_EMPLOYEE_TYPE () {  ##### SELCT EMPLOYEE TYPE #####

  echo -n "Type [ft] for full time employees and [ct] for contractors:[ft/ct]:"
  read EMPLOYEE_TYPE
  EMPLOYEE_TYPE=$(echo "${EMPLOYEE_TYPE,,}"|cut -d' ' -f1)
  if [[ "$EMPLOYEE_TYPE" != ft  &&  "$EMPLOYEE_TYPE" != ct ]]; then
    echo -n "Type [ft] for full time employees and [ct] for contractors:[ft/ct]:"
    if [[ "$EMPLOYEE_TYPE" != ft  &&  "$EMPLOYEE_TYPE" != ct ]]; then
      echo " Too many mistakes. Go back and rerun the tool again."
      exit 1
    fi
  fi
  export EMPLOYEE_TYPE

}

MANUAL_USERCREATE () {
  echo -n "Type unix/vpn/ldap user name you want to create:"
  read AUTOUSER
  export AUTOUSER
  echo "User:   $AUTOUSER">>/root/scripts/temparea/p4template
}

CHECK_USER () {
  getent passwd |grep -w "$AUTOUSER" >/dev/null 2>&1
  {
    if [ $? -eq 0 ];then
      echo "User ID: $AUTOUSER is not available. Follow next instructions."
      MANUAL_USERCREATE
    fi
  }
}

GENERATE_USER_NAME () {
  AUTOUSER=${FIRST_NAME:0:1}$LAST_NAME
  getent passwd|awk -F":" '{print $1}'|grep -w $AUTOUSER >/dev/null 2>&1
  {
    if [[ $? -eq 0 ]]; then
      echo "User Name $AUTOUSER exists."
      AUTOUSER="$FIRST_NAME"
      getent passwd|awk -F":" '{print $1}'|grep -w $AUTOUSER >/dev/null 2>&1
      {
        if [[ $? -eq 0 ]]; then
          echo "User Name $AUTOUSER exists."
          AUTOUSER="$FIRST_NAME${LAST_NAME:0:1}"
          getent passwd|awk -F":" '{print $1}'|grep -w $AUTOUSER >/dev/null 2>&1
          {
            if [[ $? -eq 0 ]]; then
              echo "User Name $AUTOUSER exists."
              AUTOUSER=$LAST_NAME${FIRST_NAME:0:1}
              getent passwd|awk -F":" '{print $1}'|grep -w $AUTOUSER >/dev/null 2>&1
              {
                if [[ $? -eq 0 ]]; then
                  echo "User Name is $AUTOUSER exists."
                  AUTOUSER=${FIRST_NAME:0:4}${LAST_NAME:0:4}
                  getent passwd|awk -F":" '{print $1}'|grep -w $AUTOUSER >/dev/null 2>&1
                  {
                    if [[ $? -eq 0 ]]; then
                      echo "User Name is $AUTOUSER is also not available."
                      echo "Please try manually."
                      exit 1
                    else
                      export AUTOUSER
                    fi
                  }

                else
                  export AUTOUSER
                fi
              }

            else
              export AUTOUSER
            fi

          }
        else
          export AUTOUSER
        fi
      }
    else
      export AUTOUSER
    fi

  }

  echo "User:   $AUTOUSER">>/root/scripts/temparea/p4template
}


CREATE_LDAP_USER() {
  echo "Now I will create Unix and VPN account with this information."
  smbldap-groupadd -g $NEW_UID $AUTOUSER
  {
    if [[ $? -ne 0 ]]; then
      echo "Unable to create Group for USER_NAME. Please investigate."
      Pause
      exit 1
    fi
  }
  echo "password is $newpass"
  smbldap-useradd -N $first_NAME -S $last_NAME -c "$first_NAME $last_NAME" \
  -u $NEW_UID -g $NEW_UID -G hw -m $AUTOUSER \
  -M "$FIRST_NAME.$LAST_NAME@barefootnetworks.com"

  {
    if [[ $? -ne 0 ]]; then
      echo "Unable to create USER_NAME. Please investigate."
      Pause
      exit 1
    else
      echo "$newpass" | smbldap-passwd -p $AUTOUSER
      echo "New User name: $AUTOUSER has been created"
    fi
  }
}

CREATE_OTHER_LDAP_USER() {
  echo "Now I will create Unix and VPN account with this information."
  smbldap-groupadd -g $NEW_UID $AUTOUSER
  {
    if [[ $? -ne 0 ]]; then
      echo "Unable to create Group for USER_NAME. Please investigate."
      Pause
      exit 1
    fi
  }
  echo "password is $newpass"
  smbldap-useradd -N $first_NAME -S $last_NAME -c "$first_NAME $last_NAME" \
  -u $NEW_UID -g $NEW_UID -G hw -m $AUTOUSER \
  -M "$OTHER_EMAIL"

  {
    if [[ $? -ne 0 ]]; then
      echo "Unable to create USER_NAME. Please investigate."
      Pause
      exit 1
    else
      echo "$newpass" | smbldap-passwd -p $AUTOUSER
      echo "New User name: $AUTOUSER has been created"
    fi
  }
}


CREATE_RADIUS_USER () {

  TMPPASS=$(smbencrypt $newpass >/tmp/xx)
  SAMBAPASS=$(cat /tmp/xx|awk '{print $2}')
  echo $SAMBAPASS
  export SAMBAPASS
  CREATE_LINE="$AUTOUSER      NT-Password := '$SAMBAPASS'"
  echo $CREATE_LINE >/tmp/xx
  ssh -q $RADSERVER "cat /etc/raddb/mods-config/files/authorize|grep $AUTOUSER"
  if [[ $? -eq 0 ]]; then
    echo "There is one radius user with same user name"
    exit 1
  else

    ssh -q $RADSERVER "perl -ni.bk -e 'print unless /\Q$AUTOUSER\E/' $RADIUSPATH && perl -pi.bk -e 'print qq/$AUTOUSER              NT-Password := '\"$SAMBAPASS\"' \n/ if eof;' $RADIUSPATH"
    ssh -q $RADSERVER 'service radiusd restart'
    if [[ $? -ne 0 ]]; then
      echo "Something is not right. I am reseting the file to previous state."
      echo "Check manually."
      ssh -q $RADSERVER 'cp /etc/raddb/mods-config/files/authorize.$DATE /etc/raddb/mods-config/files/authorize  && \
      service radiusd restart'
      Pause
    fi
  fi
}


CREATEVPN () {

  # Add the new user to vpnusers Group

  ssh -q $VPNSERVER "usermod -G vpnusers $AUTOUSER"

  # Create google-authenticator code and account for user and save it locally.

  echo "google-authenticator information:" >>/tmp/$AUTOUSER.txt
  ssh -q $VPNSERVER "su - $AUTOUSER -c 'google-authenticator -t -d -f -r 3 -R 30 -w 1'" >>/tmp/$AUTOUSER.txt
  GOOGLE_AUTHENTICATOR_CODE=$(ssh -q $VPNSERVER "echo 'https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=otpauth://totp/BarefootVPN%3Fsecret%3D'`head -1 /home/$AUTOUSER/.google_authenticator `")
  export GOOGLE_AUTHENTICATOR_CODE
}

NEED_PERFORCE () {

  echo -n "Do you need perforce account for these users ?[y|n]:"
  read READ_PERFORCE_RESPONSE
  export READ_PERFORCE_RESPONSE
}

CREATE_P4_USER () {

  cp /root/scripts/temparea/p4template /tmp
  chown ssinha:ssinha /tmp/p4template
  sudo -i -u $P4ADMIN /tools/perforce/2016.2/p4 user -i -f </tmp/p4template
  rm -f /tmp/p4template
}




##########################################################################################
# UNIX PASSWORD  RELATED FUNCTIONS
##########################################################################################

AUTO_PASS() {  ##### GENERATE PASSWORD AUTOMATICALLY #####
  NEW_PASS () {

    chars='!%_+='
    { </dev/urandom LC_ALL=C grep -ao '[A-Za-z0-9]'  | head -n$((RANDOM % 8 + 4))
      echo ${chars:$((RANDOM % ${#chars})):1}   # Random special char.
    } | shuf | tr -d '\n'

  }
  {
    newpass=$(NEW_PASS)
    passcount=$(echo $newpass | wc -m)
    echo $passcount
    while [ $passcount -lt 9 ]
    do
      newpass=$(NEW_PASS)
      passcount=$(echo $newpass | wc -m)
    done
    export newpass
    echo "New password:$newpass"
    echo "$newpass" >/root/scripts/temparea/UNIX_PASSWORD
  }
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
        echo "OK, I will use that password and will send you in an email."
        export newpass
        echo " password: $newpass" >>/tmp/$AUTOUSER.txt
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


##########################################################################################
# GOOGLE EMAIL RELATED FUNCTIONS
##########################################################################################

NEED_GMAIL_ID () {

  echo -n "Do you need GMAIL Account for this user?[y/n]:"
  read NEED_GMAIL_ID_REQUEST
  if [[ "$NEED_GMAIL_ID_REQUEST" == y ||  "$NEED_GMAIL_ID_REQUEST" == n ]]; then
    export NEED_GMAIL_ID_REQUEST
  else
    echo "You need to select one of them."
    exit 1
  fi
}


BAREFOOT_EMAIL () {

  # Changed GMAIL ID to use first initial and last name per Romi.
  #EMAIL_ID=$FIRST_NAME\.$LAST_NAME\\\@barefootnetworks\.com
  EMAIL_ID=$AUTOUSER\\\@barefootnetworks\.com
  echo "Email:    $EMAIL_ID" |sed -e 's/\\//'>>/root/scripts/temparea/p4template
  export EMAIL_ID

}

BAREFOOT_EMAIL_MANUAL () {

  CHECK_GMAIL_ACCOUNT

  GMAIL_ID=$AUTOUSER
  EMAIL_ID=$GMAIL_ID
  export EMAIL_ID
  GMAIL_ALIAS=$FIRST_NAME\.$LAST_NAME
  /root/bin/gam/gam create user "$GMAIL_ID" firstname $first_NAME lastname $last_NAME password "$newpass"  changepassword on org 'New users'
  echo "Creating Google Email Account. Pls wait........"
  /root/bin/gam/gam create alias "$GMAIL_ALIAS" user "$GMAIL_ID"
  sleep 15
  if [ "$EMPLOYEE_TYPE" == ft ];then
    /root/bin/gam/gam update group staff add member "$GMAIL_ID"
    Pause
  else
    [ "$EMPLOYEE_TYPE" == ct ]
    /root/bin/gam/gam update group contractorsonsite add member "$GMAIL_ID"
    Pause
  fi

  if [[ "$GROUP"  == hw  && "$EMPLOYEE_TYPE" == ft ]]; then
    /root/bin/gam/gam update group hw_fulltime add member "$GMAIL_ID"
  elif [[ "$GROUP"  == sw && "$EMPLOYEE_TYPE" == ft ]]; then
      /root/bin/gam/gam update group 'sw' add member "$GMAIL_ID"
  elif [[ "$GROUP"  == cust && "$EMPLOYEE_TYPE" == ft ]]; then
    /root/bin/gam/gam update group cteam add member "$GMAIL_ID"
  else
    echo "Please rerun the script."
  fi
}


CHECK_GMAIL_ACCOUNT () {

  # Changed gmail id to first initial plus last name if available.
  #GMAIL_ID=$FIRST_NAME\.$LAST_NAME
  GMAIL_ID=$AUTOUSER
  /root/bin/gam/gam info user $GMAIL_ID >/dev/null 2>&1
  {
    if [ $? -eq 0 ]; then
      echo "That email id has been taken."
      echo -n "Type a new email id for the user:"
      read GMAIL_ID
      {
        if [[ -z $GMAIL_ID ]]; then
          export GMAIL_ID
        else
          echo "You didn't type the GMAIL ID. Rerun the tool. "
          echo "Hit Enter to continue.........."
          read
          tput clear
          break
        fi
      }
    else
      export GMAIL_ID
    fi
  }
}

CREATE_GMAIL_ACCOUNT () {

  CHECK_GMAIL_ACCOUNT

  GMAIL_ID=$AUTOUSER

  echo "Creating Google Email Account. It will take about a minute..."
  /root/bin/gam/gam create user "$GMAIL_ID" firstname $first_NAME lastname $last_NAME password "$newpass"  changepassword on org 'New users'

  sleep 15
  if [ "$EMPLOYEE_TYPE" == ft ];then
    /root/bin/gam/gam update group staff add member "$GMAIL_ID"
  else
    [ "$EMPLOYEE_TYPE" == ct ]
    /root/bin/gam/gam update group contractorsonsite add member "$GMAIL_ID"
  fi
  sleep 15
  /root/bin/gam/gam create alias $FIRST_NAME\.$LAST_NAME user $AUTOUSER

  if [[ "$GROUP"  == hw  && "$EMPLOYEE_TYPE" == ft ]]; then
    /root/bin/gam/gam update group hw_fulltime add member "$GMAIL_ID"
  elif [[ "$GROUP" == hw &&  "$EMPLOYEE_TYPE" == ct ]]; then
    /root/bin/gam/gam update group hw_contractors add member "$GMAIL_ID"
  elif [[ "$GROUP"  == sw && "$EMPLOYEE_TYPE" == ft ]]; then
      /root/bin/gam/gam update group sw add member "$GMAIL_ID"
  elif [[ "$GROUP"  == cust && "$EMPLOYEE_TYPE" == ft ]]; then
    /root/bin/gam/gam update group cteam add member "$GMAIL_ID"
  else
    echo "Not adding to any extra group. Add him manually."
    Pause
  fi
}




##########################################################################################
# GENERATING TEMPLATE
##########################################################################################

GENERATE_EMPLOYEE_EMAIL ()  {
  if [[ $GROUP == hw  && $EMPLOYEE_TYPE == ft ]] ;then
    cp /root/scripts/templates/welcome_hw.html /root/scripts/templates/$AUTOUSER.html
  elif [[ $GROUP == sw && $EMPLOYEE_TYPE == ft ]]; then
    cp /root/scripts/templates/welcome_sw.html /root/scripts/templates/$AUTOUSER.html
  elif [[ $GROUP == cust && $EMPLOYEE_TYPE == ft ]]; then
    cp /root/scripts/templates/welcome_sw.html /root/scripts/templates/$AUTOUSER.html
  elif [[ $GROUP == hw && $EMPLOYEE_TYPE == ct  ]]; then
    cp /root/scripts/templates/welcome_contractors_hw.html /root/scripts/templates/$AUTOUSER.html
  elif [[[ $GROUP == cust && $EMPLOYEE_TYPE == ct  ]]; then
    cp /root/scripts/templates/welcome_contractors_sw.html /root/scripts/templates/$AUTOUSER.html
  else
    cp /root/scripts/templates/welcome_contractors_sw.html /root/scripts/templates/$AUTOUSER.html
  fi

  perl -p -i -e "s/FIRST_NAME/$first_NAME/"  /root/scripts/templates/$AUTOUSER.html
  perl -p -i -e "s/USER_NAME/$AUTOUSER/"  /root/scripts/templates/$AUTOUSER.html
  perl -p -i -e "s/UNIX_PASSWORD/$newpass/"  /root/scripts/templates/$AUTOUSER.html
  perl -p -i -e "s/EMAIL_ID/$AUTOUSER/"  /root/scripts/templates/$AUTOUSER.html
  perl -p -i -e "s/EMAIL_PASSWORD/$EMAIL_PASSWORD/"  /root/scripts/templates/$AUTOUSER.html
  sed -i  "s#GOOGLE_AUTHENTICATOR_CODE\b#$GOOGLE_AUTHENTICATOR_CODE#" /root/scripts/templates/$AUTOUSER.html
  sed -i  "s/GOOGLE_AUTHENTICATOR_CODE/\&/g" /root/scripts/templates/$AUTOUSER.html
  sed -i  "s/CT_MACHINE/$CT_MACHINE/" /root/scripts/templates/$AUTOUSER.html

}
GENERATE_OTHER_EMAIL () {

cp /root/scripts/templates/other.html /root/scripts/templates/$AUTOUSER.html
perl -p -i -e "s/FIRST_NAME/$first_NAME/"  /root/scripts/templates/$AUTOUSER.html
perl -p -i -e "s/USER_NAME/$AUTOUSER/"  /root/scripts/templates/$AUTOUSER.html
perl -p -i -e "s/UNIX_PASSWORD/$newpass/"  /root/scripts/templates/$AUTOUSER.html
sed -i  "s#GOOGLE_AUTHENTICATOR_CODE\b#$GOOGLE_AUTHENTICATOR_CODE#" /root/scripts/templates/$AUTOUSER.html
sed -i  "s/GOOGLE_AUTHENTICATOR_CODE/\&/g" /root/scripts/templates/$AUTOUSER.html

}



##########################################################################################
# SENDING EMAIL RELATED FUNCTIONS
##########################################################################################

SEND_MAIL () {

  #mutt -e 'set content_type=text/html' -s 'Welcome to Barefoot Networks' $EMAIL_ID $ADMIN $ADMIN1 $HRMAIL </root/scripts/templates/$AUTOUSER.html
  mutt -e 'set content_type=text/html' -s 'Welcome to Barefoot Networks' $ADMIN  $GMAIL_ID@barefootnetworks.com </root/scripts/templates/$AUTOUSER.html

}

SEND_OTHER_EMAIL () {

mutt -e 'set content_type=text/html' -s "Barefoot access information" -a /root/scripts/templates/barefoot-ca.crt /root/scripts/templates/barefoot.ovpn /root/scripts/templates/barefoot_vpn.zip -- $ADMIN  $ADMIN1 $OTHER_EMAIL </root/scripts/templates/$AUTOUSER.html
}

##########################################################################################
# DISABLE USER FUNCTIONS
##########################################################################################

COLLECT_DISABLE_USER_NAME () {

echo -n "I will disable Unix, VPN, WiFi & suspend Gmail Account. Type the Full Name here[Ex. John Doe]:"
  read FULL_NAME_OF_DISABLE_USER

DISABLE_USER_NAME=$(getent passwd|grep -i "$FULL_NAME_OF_DISABLE_USER" | awk -F":" '{print $1}')

charlen=$(echo ${#DISABLE_USER_NAME})
  if [ $charlen == 0 ]; then
     echo "Find the correct user name and rerun the tool. Run getent passwd|egrep 'employee name'"
     exit 1
  fi
  echo "Unix/VPN/WiFi id of $FULL_NAME_OF_DISABLE_USER is $DISABLE_USER_NAME"
export DISABLE_USER_NAME
}

COLLECT_GMAIL_ID_FOR_DISABLED_USER () {

  GMAIL_ID_OF_DISABLE_USER1=$(ldapsearch -x -b "dc=barefoot-int,dc=com" "(uid=$DISABLE_USER_NAME)" mail|grep ^mail|awk -F ": " '{print $2}'| cut -d @ -f1)
  echo "Now I am checking Google if that user exists. May take few seconds."
  /root/bin/gam/gam info user $GMAIL_ID_OF_DISABLE_USER1 >/dev/null 2>&1
  if [ $? -eq 0 ]; then
  echo "I found gmail id of $FULL_NAME_OF_DISABLE_USER is: $GMAIL_ID_OF_DISABLE_USER1"
  fi
  echo -n "If the above gmail id is correct, then type it here, or type the correct gmail id here:"
  read GMAIL_ID_OF_DISABLE_USER

  GMAIL_ID_OF_DISABLE_USER=$(echo "$GMAIL_ID_OF_DISABLE_USER"|cut -d @ -f1)

  export GMAIL_ID_OF_DISABLE_USER

}

SUSPEND_GMAIL() {

  echo "Now I will de-activate the gmail account. Press CTRL+C to cancel. Hit enter to continue."
  Pause
  /root/bin/gam/gam info user $GMAIL_ID_OF_DISABLE_USER >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    /root/bin/gam/gam update user $GMAIL_ID_OF_DISABLE_USER password 'N0T$0f&N!$' suspended on
    if [ $? -eq 0 ]; then
      echo " $FULL_NAME_OF_DISABLE_USER GMAIL-SUSPENTION : Suspended" >/tmp/$FULL_NAME_OF_DISABLE_USER.txt
    else
      echo "Could not disable  $FULL_NAME_OF_DISABLE_USER, check manually. "
      echo " $FULL_NAME_OF_DISABLE_USER GMAIL-SUSPENTION : Failed" >/tmp/$FULL_NAME_OF_DISABLE_USER.txt
      Pause
    fi
  fi

}

DISABLE_RADIUS () {

  ssh -q $RADSERVER "sed -i.$DATE '/^$DISABLE_USER_NAME/d' $RADIUSPATH && service radiusd restart" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echo " I think Radius Server is broken. Please logon to $RADSERVER and check it."
    Pause
    exit 1
  else
    echo "Removed radius(WiFi) access of $DISABLE_USER_NAME."
    echo " $FULL_NAME_OF_DISABLE_USER WiFi Access : disabled" >>/tmp/$FULL_NAME_OF_DISABLE_USER.txt
  fi

}

DISABLE_LDAP_VPN () {

  smbldap-usermod --shadowexpire 0 $DISABLE_USER_NAME
  smbldap-usermod -L $DISABLE_USER_NAME

  ssh -q $VPNSERVER "sed -i.bak 's/$DISABLE_USER_NAME//' $VPNGROUP"
  echo "I have just disabled Unix & VPN Account for $FULL_NAME_OF_DISABLE_USER"
  echo " $FULL_NAME_OF_DISABLE_USER VPN Access : disabled" >>/tmp/$FULL_NAME_OF_DISABLE_USER.txt
  echo " $FULL_NAME_OF_DISABLE_USER LDAP Access : disabled" >>/tmp/$FULL_NAME_OF_DISABLE_USER.txt
}

REMOVE_PERFORCE_CLIENT () {
  echo "Now I need to the perforce cleanup."
  OPEN_CLIENTS=$(sudo -i -u $P4ADMIN $P4COMMAND clients -u $DISABLE_USER_NAME |awk '{print $2}'|sort -u)
  echo "$FULL_NAME_OF_DISABLE_USER has folling open clients:${OPEN_CLIENTS[*]}"
  echo "CTRL+C to cancel or press Enter to cleanup perforce."
  echo "If you cancel then you need to do it manually later."
  read
  sudo -i -u $P4ADMIN $P4COMMAND clients -u $DISABLE_USER_NAME |awk '{print $2}'|sort -u|while read P4CLIENTS; do sudo -i -u $P4ADMIN $P4COMMAND client -d -f $P4CLIENTS; done
}

REMOVE_PERFORCE_LICENSE () {

sudo -i -u $P4ADMIN $P4COMMAND user -d -f $DISABLE_USER_NAME
cat /tmp/p4delete_result|egrep "can't be deleted"
  if [ $? -eq 0 ];then
    cat /tmp/p4delete_result | mailx -s "DISABLE_USER_NAME"
    mutt -e 'set content_type=text/html' -s 'Unable to remove perforce license' $ADMIN  $ADMIN1  </tmp/p4delete_result
  else
    echo " $FULL_NAME_OF_DISABLE_USER Perforce license : Removed" >>/tmp/$FULL_NAME_OF_DISABLE_USER.txt
  fi

}

DELETE_USER () {

  echo -n "Type the user name:"
  read DELETE_USER_NAME
  if GetYesNo "Do you want to remove  $DELETE_USER_NAME? [y/n]:"
  then
    echo "/home/$DELETE_USER_NAME will not be deleted. This feature is"
    echo "available only for testing scripts only. DO NOT use this to remove"
    echo "any user who left company. Ask Management before removing"
    echo "any file/folder. Will remove the user id/group only from LDAP/VPN/Radius."
    echo "Press ctrl+c if you don't want to run this feature."
    Pause
    smbldap-userdel $DELETE_USER_NAME
    smbldap-groupdel $DELETE_USER_NAME
    # Remove Radius access and varify if it still ok after running the script.
    ssh -q $RADSERVER "sed -i.$DATE '/^$DELETE_USER_NAME/d' $RADIUSPATH && service radiusd restart"
    {
      if [[ $? -ne 0 ]]; then
        echo " I think Radius Server is broken. Please logon to $RADSERVER and check it."
      else
        echo "Removed radius(WiFi) access of $DELETE_USER_NAME."


      fi
    }

    # Now remove vpn access
    ssh -q $VPNSERVER "sed -i.bak 's/$DELETE_USER_NAME//' $VPNGROUP"
  else
    echo "You have selected not to deactivate $DELETE_USER_NAME. Goodbye"
    Pause
  fi

}


##########################################################################################
# OTHER TASKS FUNCTIONS
##########################################################################################


GET_GMAIL_EMAILS () {

  echo -n "Staff or Contractors email list?[Ex. staff/contractors]:"
  read EMAIL_GROUP
  EMAIL_GROUP="$(echo $EMAIL_GROUP | tr '[:upper:]' '[:lower:]')"

}

GET_VALID_EMAIL_ID()	{

  while :
  do
    echo -n "Please enter valid Barefoot email of the recepient:]"
    read RECEPIENT_EMAIL
    RECEPIENT_EMAIL="$(echo $RECEPIENT_EMAIL | tr '[:upper:]' '[:lower:]')"
    case "$RECEPIENT_EMAIL" in
      *@barefootnetworks.com)		return 0  ;;
      * ) clear ;;
    esac
  done

}

COLLECT_EMAILS () {

  if [ "$EMAIL_GROUP" == contractors ]; then
    /root/bin/gam/gam info org Contractors | egrep \@barefootnetworks.com |sed '/Got/d' >/tmp/email_list
  fi
  /root/bin/gam/gam info group $EMAIL_GROUP | grep member | awk '{print $2}' | sed '/false/d' >/tmp/email_list

  cat /tmp/email_list| grep -v false | mailx -s "Email list for $EMAIL_GROUP" -r "itsupport@barefootnetworks.com(Barefoot IT)" $RECEPIENT_EMAIL
  rm -f /tmp/email_list
}

COLLECT_OTHER_EMAIL () {

echo -n "Type the email id of the user:"
read OTHER_EMAIL
export OTHER_EMAIL
echo "Email:    $OTHER_EMAIL" |sed -e 's/\\//'>>/root/scripts/temparea/p4template

}

SHARED_DRIVE_ACCESS () {
  clear
  echo "Shared Drive Access is restricted to Full time employees only. Check with Glen for employees based on other countries."
  echo -n "Are you sure you want to add shared drive access?[y/n]:"
    read ANSWER1
  echo -n "Did you move the user to correct Org unit already [ Ex. Barefoot.com/Contractors] ?[y/n]:"
  read ANSWER2
  if [[ "$ANSWER1" == y  ]] && [[ "$ANSWER2" == y ]]; then
    echo -n "Type the gmail id of the employee:"
    read GMAIL_ID_SHARED
    echo "Ok, I will verify before proceeding. Pls wait..."

    /root/bin/gam/gam info user $GMAIL_ID_SHARED >/dev/null 2>&1
    if [[  $? -ne 0 ]]; then
      echo "Please type proper gmail id and try again."
      Pause
      exit 1
    else
      /root/bin/gam/gam info user $GMAIL_ID_SHARED | egrep "Org Unit"|egrep Contractors >/dev/null 2>&1
      if [[ $? -eq 0 ]]; then
        echo "Contractors are not allowed to access shared drive. Goodbye."
        Pause
        exit 1
      else
        /root/bin/gam/gam info user $GMAIL_ID_SHARED |egrep "2-step enrolled: True" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
          echo "Two Factor not enabled for $GMAIL_ID_SHARED. Make sure user enabled TFA before trying again."
          Pause
          exit 1
        else
          echo " Please wait......."
          /root/bin/gam/gam update group "Barefoot Shared Folder Access" add member "$GMAIL_ID_SHARED" >/dev/null 2>&1
            if [ $? -eq 0 ];then
              mailx -s "Google Team Drive Access enabled." -r "itsupport@barefootnetworks.com (Barefoot IT Support)" $GMAIL_ID_SHARED </dev/null
            else
              echo "Login to gmail admin account and check why it didn't work."
              Pause
              exit 1
            fi
          fi
        fi
      fi
  else
    echo "Please check with Glen for non US employee and move the user to correct org unit."
    echo "This part intentionally left manual. In future it can be automated too"
    Pause
  fi


}


ADD_SSHD_ACCESS () {

  add_server_user_info() {
    echo -n "SERVER NAME: "
    read HOST_NAME
    echo -n "USER NAME: "
    read USER_NAME
    FILE_NAME=/etc/ssh/sshd_config
  }

check_hostname() {
  nslookup $HOST_NAME 2>&1 >/dev/null
  if [ $? -ne 0 ];then
    echo "Please check the Server Name Again"
    exit 250
  fi
  getent passwd |grep $USER_NAME 2>&1 >/dev/null
    if [ $? -ne 0 ];then
      echo "Please check the User Name again."
      exit 251
    fi
}

add_users_now() {
  ssh -q $HOST_NAME -o ConnectTimeout=2 "cat $FILE_NAME |grep -w $USER_NAME" 2>&1 >/dev/null
  if [ $? -ne 0 ];then
    ssh -q $HOST_NAME -o ConnectTimeout=2 "perl -pi.bk -pe 's/AllowUsers.*\K/ $USER_NAME/;' $FILE_NAME && service sshd restart 2>&1 >/dev/null"
    if [ $? -eq 0 ];then
      echo "User name:$USER_NAME successfully addded to the Server:$HOST_NAME."
    else
      echo "Something is wrong please do it manually."
    fi
  else
    echo "User name:$USER_NAME already has access to $HOST_NAME Server."
  fi
}


##########################################################################################
# DEFINE TASKS
##########################################################################################
CREATE_EMPLOYEE_ACCOUNT () {

  GET_UID
  COLLECT_USER_NAME
  SELECT_EMPLOYEE_TYPE
  SELECT_GROUP
  Pause
  NEED_GMAIL_ID
  BAREFOOT_EMAIL
  GENERATE_USER_NAME
  AUTO_PASS
  CREATE_LDAP_USER
  CREATE_RADIUS_USER
  CREATEVPN
  GENERATE_EMPLOYEE_EMAIL
  Pause
  if [ "$NEED_GMAIL_ID_REQUEST" == y ]; then
    CREATE_GMAIL_ACCOUNT
  fi
  SEND_MAIL
  if [ $GROUP == hw ] ;then
    CREATE_P4_USER
  fi

}


MANUAL_EMPLOYEE_ACCOUNT () {
  GET_UID
  COLLECT_USER_NAME
  MANUAL_USERCREATE
  AUTO_PASS
  SELECT_EMPLOYEE_TYPE
  SELECT_GROUP
  BAREFOOT_EMAIL_MANUAL
  CREATE_LDAP_USER
  CREATE_RADIUS_USER
  CREATEVPN
  GENERATE_EMPLOYEE_EMAIL
  SEND_MAIL
  if [ $GROUP == hw ] ;then
    CREATE_P4_USER
  fi

}

GET_EMAILS () {
  GET_GMAIL_EMAILS
  GET_VALID_EMAIL_ID
  COLLECT_EMAILS
}

DISABLE_USER_ACCESS () {
  COLLECT_DISABLE_USER_NAME
  COLLECT_GMAIL_ID_FOR_DISABLED_USER
  SUSPEND_GMAIL
  DISABLE_LDAP_VPN
  DISABLE_RADIUS
  REMOVE_PERFORCE_CLIENT
  REMOVE_PERFORCE_LICENSE
}

GIVE_VPN_WIFI_ACCESS () {
  GET_UID
  COLLECT_USER_NAME
  GENERATE_USER_NAME
  COLLECT_OTHER_EMAIL
  NEED_PERFORCE
  if [[ "$READ_PERFORCE_RESPONSE" == y ]]; then
    CREATE_P4_USER
  fi
  AUTO_PASS
  Pause
  CREATE_OTHER_LDAP_USER
  CREATE_RADIUS_USER
  CREATEVPN
  GENERATE_OTHER_EMAIL
  SEND_OTHER_EMAIL

}

CALL_MAN_PAGE () {
  clear
  man manageuser
}

##########################################################################################
#                              MAIN SECTION
##########################################################################################

MANAGEUSER_MAIN_MENU()  {


  tput clear
  echo "               $blink$reverse   IT  User Management Tool     $offblink$offbold"
  echo "                              $reverse  $offbold "
  echo "$reverse                                                                $offbold "
  echo "$reverse  $offbold  1. New employee account creation(Auto)                    $reverse  $offbold"
  echo "$reverse  $offbold  2. New employee account creation(Manual)                  $reverse  $offbold"
  echo "$reverse  $offbold  3. Deactivate account (employee exit)                     $reverse  $offbold"
  echo "$reverse  $offbold  4. Only OpenVPN & WiFi account creation                   $reverse  $offbold"
  echo "$reverse  $offbold  5. Give ssh permission to user to unix server             $reverse  $offbold"
  echo "$reverse  $offbold  6. SHARED_DRIVE_ACCESS                                    $reverse  $offbold"
  echo "$reverse  $offbold  7. Only OpenVPN Account                                   $reverse  $offbold"
  echo "$reverse  $offbold  8. Create GMAIL alias                                     $reverse  $offbold"
  echo "$reverse  $offbold  9. Get member list of Google Groups                       $reverse  $offbold"
  echo "$reverse  $offbold  d. Delete user(for testing users only)                    $reverse  $offbold"
  echo "$reverse  $offbold  t. New Function testing area                              $reverse  $offbold"
  echo "$reverse  $offbold  h. Help/FAQ                                               $reverse  $offbold"
  echo "$reverse  $offbold  q. Quit or CTRL+C any time to quit                        $reverse  $offbold"
  echo "$reverse  $offbold                                                            $reverse  $offbold"
  echo "$reverse                                                                $offbold "
  echo "$reverse  $offbold                  Barefoot Networks                         $reverse  $offbold"
  echo "$reverse                                                                $offbold "
  echo -n "               SELECT ONE OPTION :"
}


while :
do
  MANAGEUSER_MAIN_MENU
  read SELECTION
  case $SELECTION in
    1) CREATE_EMPLOYEE_ACCOUNT
    ;;

    2) MANUAL_EMPLOYEE_ACCOUNT
    ;;

    3) DISABLE_USER_ACCESS
    ;;

    4) GIVE_VPN_WIFI_ACCESS
    ;;

    5) ADD_SSHD_ACCESS
    ;;

    6) SHARED_DRIVE_ACCESS
    ;;

    7) echo "Not available yet"
      Pause
    ;;

    8) echo "Not available yet"
    ;;

    9) GET_EMAILS
    ;;

    d) DELETE_USER
    ;;

    t) echo "Test new functions before adding to main tool."
    Pause
    ;;

    h) CALL_MAN_PAGE
    ;;

    Q|q) clear
      exit
    ;;
    *)
      tput clear
      echo "\007\007\007\c"
      echo "\nThis Choice doesn't exist. Pls choose one from Menu\n"
    ;;
  esac
done




