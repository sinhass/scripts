#!/usr/bin/ksh
# Author : Siddhartha Sankar Sinha
# Rev    : 2.1
# Date   : 08-11-2009
# Rev    : 2.2
# Date   : 11-07-2010
# Added new features
# Rev    : 2.3
# Date   : 11/10/2010
# Added SSHD Modification Features
# Rev    : 2.4
# Date   :11-12-2010
# Added Function to fix broken ML/TL levels
# Rev    : 2.5
# Date   : 10/13/2011
# Fixed zero disk size issue
##################################################
# This is First Boot Scripts for NIM Servers
##################################################
#
#
# DEFINING SOME FUNCTIONS AND VARIABLES WE NEED LATER 
#
########################################################
OSVER=`oslevel -r|cut -c 1-2`
OSLEVEL=$(oslevel -r|cut -c 1-2|sed 's/.$/\.&/')
#
#################################################################
# MAN PAGE INSTALLTION FUNCTIONS
#################################################################
#
INST_MAN()
{
 OSLEVEL=$(oslevel -r|cut -c 1-2|sed 's/.$/\.&/')
    if [ $OSLEVEL = 5.3 ];then
     installp -aXYgvd/utility infocenter.man.EN_US.commands 5.3.7.0
       elif [ $OSLEVEL = 6.1 ];then
      installp -aXYgvd/utility infocenter.man.EN_US.files 6.1.2.0
     else
   echo "I don't have any man page to install"
 fi
}
##################################################################
# Install GPFS
#################################################################
#
INST_GPFS()
{
   if [ $OSLEVEL = 5.3 -o $OSLEVEL = 6.1 ];then
      installp -aXYgvd /utility gpfs.base gpfs.docs gpfs.msg.en_US 
   fi
  }
#
#
INST_OPENSSH()
{
   echo "Installing Openssh"
     installp -aXYgvd /utility openssl.base 
        OS_LEVEL=$(oslevel -s|cut -c1-10|sed -e s'/\-//g')
           if [ $OS_LEVEL -gt 53000404 ];then
	     /usr/sbin/installp -aXYgvd /utility/openssh.base.5.4.0.6100.I all 
else
       /usr/sbin/installp -aXYgvd /utility openssh.base.server 5.0.0.5300 openssh.base.client 5.0.0.5300
         {
           lssrc -s sshd|grep active
              if [ $? -ne 0 ];then
                installp -aXYgvd /utility openssh.base
                    fi
                          }
            fi
  }
#
#
INST_OPENSSH2()
{
   echo "Trying to install Openssh for 2nd times"
            installp -ug openssl.base 
                installp -ug openssh.base 
  installp -aXYgvd /utility openssl.base 
        installp -aXYgvd /utility openssh.base.server
              lssrc -s sshd|grep active
                    if [ $? -ne 0 ];then
  echo "Failed to install Openssh. Install manually"
         fi
}
##########################################################################
# NOW WE WILL INSTALL ALL THE DRIVERS
##########################################################################
#
#
#########################################################################
# INST_DRVR
#########################################################################
INST_DRVR()
{
  cd /utility
    tput smso
      echo "Now running BCRS Customization Script on this Server"
      echo "Author: Siddhartha Sankar Sinha"
      echo "Please wait....                 "
             tput rmul
             tput rmso
      echo "Installing Drivers................................"

/usr/sbin/inutoc /utility 
  /usr/sbin/installp -acXYgvd /utility rpm.rte 
     /usr/bin/rpm -iv wget-1.9.1-1 
	/usr/sbin/chfs -a size=4000M /utility 
	   /usr/sbin/chfs -a size=2000M /opt 
	/usr/sbin/chfs -a size=1000M /tmp 
      /usr/sbin/chfs -a size=800M /var 
    /usr/sbin/installp -aXYgvd /utility devices.fcp.disk.ibm.mpio.rte devices.sddpcm
#   /usr/sbin/installp -acXYgd /utility devices.fcp.disk.ibm.mpio.rte devices.fcp.disk.ibm2105 32.6.100.31 ibmpfe.essutil 1.0.9.0 devices.sdd 1.7.2.1 
  /usr/sbin/installp -aXYgvd /utility Atape.driver 
    /usr/sbin/installp -aXYgvd /utility atldd.driver 
       /usr/sbin/installp -aXYgvd /utility devices.scsi.tape.stk.rte 
          /usr/sbin/installp -aXYgvd /utility devices.fcp.tape.stk.rte 
             /usr/sbin/installp -aXYgvd /utility EMC.Symmetrix.aix.rte 
                /usr/sbin/installp -aXYgvd /utility EMC.Symmetrix.fcp.rte 
                  /usr/sbin/installp -aXYgvd /utility EMC.Symmetrix.fcp.MPIO.rte 
                 /usr/sbin/installp -aXYgvd /utility EMC.CELERRA.aix.rte 
                /usr/sbin/installp -aXYgvd /utility EMC.CLARiiON.aix.rte 
               /usr/sbin/installp -aXYgvd /utility EMC.CLARiiON.fcp.MPIO.rte 
              /usr/sbin/installp -aXYgvd /utility EMC.CLARiiON.fcp.PowerMPIO.rte 
             /usr/sbin/installp -aXYgvd /utility EMC.CLARiiON.fcp.rte 
            /usr/sbin/installp -aXYgvd /utility EMC.CLARiiON.ha.rte 

if [ $OSVER = 51 ]; then
   {
      /usr/sbin/installp -aXYgvd /utility devices.fcp.disk 5.1.0.50 
	/usr/sbin/installp -aXYgvd /utility devices.fcp.disk.array 5.1.0.50 
	  /usr/sbin/installp -aXYgvd /utility devices.fcp.tape 5.1.0.50 
	    /usr/sbin/installp -aXYgvd /utility devices.pci.df1000f7 5.1.0.50 
	       /usr/sbin/installp -aXYgvd /utility devices.pci.df1000f7 5.1.0.35 
	      /usr/sbin/installp -aXYgvd /utility devices.pci.df1000f9 5.1.0.15 
	     /usr/sbin/installp -aXYgvd /utility devices.pci.df1000f9 5.1.0.35 
	    /usr/sbin/installp -acXYgd /utility devices.sdd 1.7.2.1 
	   /usr/sbin/installp -acXYgd /utility devices.sdd 1.7.2.1 
	  /usr/sbin/installp -aXYgvd /utility devices.pci.df1080f9 5.1.0.0  
       } 
    fi
  }
##########################################################
# COPY_FILES
##########################################################
COPY_FILES()
{
 echo " Now Copying some required files ........"
  cp /utility/motd /etc/motd 
#   cp /utility/profile /.profile 
    cp /utility/.profile.sid /.profile 
     cp /utility/osload /usr/sbin 
      cp /utility/sendmail.cf /etc/mail
       chfs -a size=3000M /usr 
          echo "Now changing permission for the scripts........."
            /usr/bin/chmod +x /utility/*sh 
              /usr/bin/chmod +x /utility/* 
            /usr/bin/chmod +x /utility/inq* 
         /usr/bin/chmod +x install* 
      /usr/bin/chmod +x copy* 
    /usr/bin/chmod +x binextr* 
 /usr/bin/chmod +x instrpm 
/usr/bin/chmod +x *.bin 
  /usr/bin/stopsrc -s sshd 
    /usr/bin/startsrc -s sshd 
        cp /utility/ntp.conf /etc/ntp.conf 
           /usr/bin/startsrc -s xntpd 
         /usr/bin/stopsrc -s sendmail >/dev/null 2>&1
       /usr/bin/startsrc -s sendmail >/dev/null 2>&1
    }
#
##################################################################################
# UNCOMMENT THE NEXT LINE TO ENABLE AUTOMATIC CD/DVD MOUNT & EJECT COMMANDS
##################################################################################
#
#mkitab "cdromd:2:boot:/usr/bin/startsrc -s cdromd >/dev/console 2>&1" 
# 
####################################################################################
# NOW I WILL MAKE SOME MODIFICATION ON ENVIRONMENT FILES
####################################################################################
#
CH_ENV()
{
 chsec -f /etc/security/limits -s default -a fsize=-1 
  chitab "cons:0123456789:respawn:/usr/sbin/getty /dev/console" 
   init q
     /usr/bin/sed '/PATH/s/$/\:\/utility/g' /etc/environment >/etc/environment.new && mv /etc/environment.new /etc/environment
       /usr/bin/sed '/xntpd/s/^#//' /etc/rc.tcpip >/etc/rc.tcpip.NEW && mv /etc/rc.tcpip.NEW /etc/rc.tcpip
          chmod 774 /etc/rc.tcpip
            chmod -R +x /utility/* 
               echo "Checking again xntpd is running or not. If not I will start"
            lssrc -s xntpd|grep active 
          if [ $? -ne 0 ];then
        startsrc -s xntpd 
     fi
   }
INSTALL_AIO_DEVICE()
{
  OSLEVEL=$(oslevel -r|cut -c 1-2|sed 's/.$/\.&/')
    if [ $OSLEVEL != 6.1 ];then
      echo "Installing AIO Device"
         mkdev -l aio0
      chdev -l aio0 -P -a autoconfig='available'
     fi
   }
##################################################################################
# FIX_BROKEN_FILESET
##################################################################################
# This portion of the script will fix any broken fileset and bring the server to
# correct OS level
#################################################################################
FIX_BROKEN_FILESET()
{
#lppchk -v 2>/tmp/lppchk_err
#         {
          #if [ -s /tmp/lppchk_err ];then
          #  egrep -v "lppchk|state"  /tmp/lppchk_err|awk '{print $1}'|sed -e '/^ *$/d'|while read X
          #          do
          #               installp -ug $X
          #          done
                    instfix -i|grep -i ml|grep -i not|awk '{print $5}'|while read Y
                      do
                          instfix -icqk $Y |grep -i ":-:"|awk -F":" '{print $2}'
                             done| sort -u | while read BROKEN_SET
                                 do
                         installp -ug $BROKEN_SET
                    done
           #                 fi
                            #  }
				}
#
###################################################################################
# NOW I WILL WIPE OUT ANYTHING I CAN SEE IS NOT IN ACTIVE VOLUME GROUP
###################################################################################
#
###################################################################################
WIPE_DATA()
{
   echo "Now running dd to wipe out data from all disks except those are on rootvg"
     /utility/erase_disk.sh 
       echo "Now running the disktest script to wipe out again"
         /utility/disktest.sh 
   }
#
###################################################################################
# NOW I AM GOING TO CHANGE SOME NETWORK PARAMETER
###################################################################################
#
CH_NET()
{
    echo "Now fine tuning some network parameters........."
       /usr/sbin/no -p -o bcastping=1
          /usr/sbin/no -po tcp_recvspace=262140
             /usr/sbin/no -po tcp_sendspace=65535
                /usr/sbin/no -po udp_sendspace=262140
                     /usr/sbin/no -po tcp_sendspace=65535
                         echo "Now I will copy the latest Firmwares. You need to run"
                 echo "diag command and update them manually "
              cd /utility
           tar -xvf MICROCODE.tar 
        cp /utility/microcode/* /usr/lib/microcode 
    installp -C 
/utility/printmap
}
#
FIX_SSHD()
{
/usr/bin/stopsrc -s sshd
sed -e s'/^\#PermitRootLogin/PermitRootLogin/'\
    -e s'/^\#PermitEmptyPasswords no/PermitEmptyPasswords yes/'\
    -e s'/^\#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config\
>/etc/ssh/sshd_config.NEW && mv /etc/ssh/sshd_config.NEW /etc/ssh/sshd_config
/usr/bin/startsrc -s sshd
}
#
ADD_ROUTE()
{
route delete default 172.21.64.2
chdev -l inet0 -a route=net,default,172.21.64.1
}
#
#
#
echo "Please wait 4-6 minutes as I am going to do a lot of BCRS Customization"
/usr/bin/rpm -i /utility/enscript-1.6.1-3.aix4.3.ppc.rpm >/dev/null 2>&1
INST_DRVR >/dev/null 2>&1
#INST_MAN >/dev/null 2>&1
INST_GPFS >/dev/null 2>&1
INST_OPENSSH >/dev/null 2>&1
COPY_FILES >/dev/null 2>&1
CH_ENV >/dev/null 2>&1
INSTALL_AIO_DEVICE >/dev/null 2>&1
CH_NET >/dev/null 2>&1
INST_OPENSSH  >/dev/null 2>&1
FIX_SSHD >/dev/null 2>&1
ADD_ROUTE >/dev/null 2>&1
WIPE_DATA >/dev/null 2>&1
lssrc -s sshd|grep active >/dev/null 2>&1
if [ $? -ne 0 ]; then
INST_OPENSSH2 >/dev/null 2>&1
FIX_BROKEN_FILESET  >/dev/null 2>&1
echo "Check the Network printer for the latest Hardware Map I am printing"
fi
echo "End of IBM BCRS Customization and loading drivers"
echo "Thanks for your patience."
