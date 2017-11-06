#!/usr/bin/ksh
# Author : Siddhartha S Sinha
# Rev : 1.0
# This file will help to create and define NIM images
# for the clients you want to load
#
#
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
# Here we will define Pause Function
#
Pause()
{
        echo ""
        echo "Hit Enter to clear the Screen and Continue........"
        read
tput clear
}
echo off
export TERM=vt320
tput clear

# THIS IS MAIN SECTION
# Here you will select whether to load  mksysb or the rte
#
#
if  GetYesNo "Are you going to load mksysb image for your client[y/n] ?";
then 
lsnim -t mksysb
     { 
	if GetYesNo "Do you see the mksysb image you want[y/n] ?";
	 then
	  echo "Type the mksysb name here:\c" ;
	    read _MKSYSB_NAME
             echo "You selected $_MKSYSB_NAME"
	      { 
	        if GetYesNo "Do you want to make any correction[y/n]?";
                 then
                  echo "Now type the name correctly:\c"
                   read _MKSYSB_NAME
		fi	
	      }

        echo  "What OS version you want to load."
        echo "For Example : AIX 61, 53, 52, 51 or 43"
        echo "Just type like 61 or 53 or 52"
        echo "Now type here:\c"
                read _AIX_LEVEL
                        {
                          if GetYesNo "Do you want to make any correction [y/n] ?" ;
                            then
                              echo "Now type is correctly as shown above:\c"
                                 read _AIX_LEVEL
                          fi
                            }

        echo "Now I will display the Selected OS and TL/ML levels availavle."
        echo "Pls choose carefully."
        lsnim -t lpp_source|grep -i $_AIX_LEVEL|awk '{printf $1"\t"}'
        echo "Now select the the OS and level you want."
        echo "Type now here:\c"
        read _AIX_LPP_TO_LOAD
        echo "Type the client name you want to load OS:\c"
        read _CLIENT_NAME_FOR_MKSYSB
        nim -o bos_inst -a source=mksysb -a mksysb=$_MKSYSB_NAME -a spot=`echo $_AIX_LPP_TO_LOAD|sed -e 's/lpp/spot/g'`\
  -a lpp_source=$_AIX_LPP_TO_LOAD -a accept_licenses=yes -a bosinst_data=Prompted_Load_For_Customer -a no_client_boot=yes \
  -a force_push=no $_CLIENT_NAME_FOR_MKSYSB

        else
             { if GetYesNo "Do you want to define one mksysb [y/n]?" ;
		then
                echo "Then answer my questions here."
                echo "What is the name of the client ?"
                echo "Ex. The name in the config sheet"
                echo "Type the name here:\c"
                read _CLIENT_NAME_FOR_MKSYSB
                { if GetYesNo "Do you need any correction[y/n]?" ;
                  then
                  echo "Type now, no mistake again.:\c"
                  read _CLIENT_NAME_FOR_MKSYSB
                 fi
                }
                echo "Type the full path  of the image, including image name."
                echo "For Example /images/bcrs/nimrod.mksysb"
		echo "Type the the full path here:\c"
	        read _MKSYSB_IMAGE_LOCATION
                 { if GetYesNo "Do you need any correction[y/n]?" ;
		   then
                     echo "Type now, no mistake again.:\c"
                     read _MKSYSB_IMAGE_LOCATION
                   fi
                  }
		nim -o define -t mksysb -a server=master -a location=$_MKSYSB_IMAGE_LOCATION "$_CLIENT_NAME_FOR_MKSYSB"_MKSYSB

		echo "Now your mksysb is defined and the name is $_MKSYSB_NAME"
		echo "Now I will ask you some more question before I proceed."
		echo  "What OS version you want to load."
       		echo "For Example : AIX 61, 53, 52, 51 or 43"
       		echo "Just type like 61 or 53 or 52"
       		echo "Now type here:\c"
        	read _AIX_LEVEL
        		{
          		  if GetYesNo "Do you want to make any correction [y/n] ?" ;
             		    then
                	      echo "Now type is correctly as shown above:\c"
                                 read _AIX_LEVEL
                          fi
                            }
	
		echo "Now I will display the Selected OS and TL/ML levels availavle."
        	echo "Pls choose carefully."
		lsnim -t lpp_source|grep -i $_AIX_LEVEL|awk '{printf $1"\t"}'
		echo "Now select the the OS and level you want."
		echo "Type now here:\c"
		read _AIX_LPP_TO_LOAD
		echo "Type the client name you want to load OS:\c"
		read _CLIENT_NAME_FOR_MKSYSB
	nim -o bos_inst -a source=mksysb -a mksysb="$_CLIENT_NAME_FOR_MKSYSB"_MKSYSB -a bosinst_data=Prompted_Load_For_Customer  \
        -a spot=`echo $_AIX_LPP_TO_LOAD| sed -e 's/lpp/spot/g'` -a lpp_source=$_AIX_LPP_TO_LOAD -a accept_licenses=yes \
        -a no_client_boot=yes -a force_push=no $_CLIENT_NAME_FOR_MKSYSB
					
				fi	
					}
	fi
		}
else
	{ 
	
		echo "What OS version you want to load."
        	echo "For Example : AIX 61, 53, 52, 51 or 43"
        	echo "Just type like 61 or 53 or 52 or 43"
        	echo "Now type here:\c"
        	read _AIX_LEVEL
       			{ 
          			if GetYesNo "Do you want to make any correction [y/n] ?" ;
             			then
                 		echo "Now type is correctly as shown above:\c"
                 		read _AIX_LEVEL
                 		fi
			}
	
		echo "Now I will display the Selected OS and TL/ML levels availavle."
                echo "Pls choose carefully."
                lsnim -t lpp_source|grep -i $_AIX_LEVEL|awk '{printf $1"\t"}'
                echo "Now select the the OS and level you want."
		echo "Just select the LPP_SOURCE, SPOT will be selected automatically"
                echo "Type now here:\c"
                read _AIX_LPP_TO_LOAD
		echo "Type the few letters of the client you want to load"
		typeset -u
        	echo "Example : p6m2a or P6M2A. It will display all the lpars"
		echo "Type here:\c"
		read _READ_CLIENT
		lsnim -c machines |grep -i $_READ_CLIENT|awk '{printf $1"\t"}'
		echo "Now type the Client you want to load OS:\c"
        	typeset -l
		read _CLIENT_NAME
	        if GetYesNo "Do you want to select No_Prompt [y/n] ?" ;
 	        then	
                NO_PROMPT=`lsnim -t bosinst_data|grep -i no|awk '{print $1}'`
                fi
		if GetYesNo "Do you want to select Install_Drivers [y/n] ?";
	        then
                INSTALL_DRIVERS=`lsnim -t fb_script|awk '{print $1}'`
		fi
		if GetYesNo "Do you want to select FTPSCR [y/n]?";
		then
		FTPSCR=`lsnim -t script|awk '{print $1}'`
		echo "Now I will define the AIX image for the client"
		nim -o bos_inst -a source=rte -a spot=`echo $_AIX_LPP_TO_LOAD| sed -e 's/lpp/spot/g'` \
                -a lpp_source=$_AIX_LPP_TO_LOAD -a accept_licenses=yes  -a no_client_boot=yes -a force_push=no\
		-a bosinst_data=$NO_PROMPT -a script=$FTPSCR -a fb_script=$INSTALL_DRIVERS $_CLIENT_NAME

fi
	 } 
fi

