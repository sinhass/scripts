#!/usr/bin/ksh
# Author : Siddhartha Sinha
# Rev    :1.0
# Date 01-14-2009
# This Script will copy the Lpp_Source directories to the remote
# Server which you want to build as NIM Server. It will not create
# any vg/lv/fs on the remote server. It will blindly copy the 
# directories you will mention
# Here we will define Yes/No Function.
#
GetYesNo()      {
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
                [yY] | yes | YES | Yes)         return 0 ;;
                [nN] | no  | NO  | No )         return 1 ;;
                * ) echo "Please Enter y or n."          ;;
        esac
tput clear
done
}
#
#
#
# Here will define Copy_Lpp Function
CopyLpp()
        {
          echo "Tell me what LPP_Source you want to copy . Ex type 61 for AIX 6.1    "
          echo "type 53 for AIX 5.3, 5.2 for AIX 5.2, 51 for AIX 5.1, 43 for AIX4.3.3"
          echo "Now enter here what you want copy:\c"
          read _LPP_SOURCE
          lsnim -t lpp_source|grep $_LPP_SOURCE|awk '{printf $1"\t"}'
          echo "Now select the lpp_source you want to copy"
          read _NEW_LPP_SOURCE
          echo "Now tell me the IP Address or hostname of the Server you want to copy to."
          echo "Type here :\c"
          read _REMOTE_SERVER_ADDRESS
          #echo "Now tell me the location you want to copy. Ex. /export/lpp_source "
	  #echo "Type the Full Path here:\c"
          #read _REMOTE_PATH
          echo "Now I am copying the specified directory to the remote Server"
          echo "It might ask for root password if you already set it in the remote"
          echo "Server. Enter the root password if it asks"
          PATH_TO_COPY=`lsnim -l $_NEW_LPP_SOURCE|grep -i location|awk -F"=" '{print $2}'|sed -e 's/^ //g'`
          rcp -rp $PATH_TO_COPY $_REMOTE_SERVER_ADDRESS:/$PATH_TO_COPY
     }

while :
do
if GetYesNo "Do you want to Copy the LPP_Soures to the remote Server [y/n] : ";
   then
     CopyLpp 
else
break
fi
done
