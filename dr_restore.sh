#!/bin/ksh
# Add a " -x" after /bin/sh to view in a DEBUG mode shell!
################################################################################
# Licensed Materials - Property of IBM
#
# (c) 1998-2002 International Business Machines Corporation.
#     All rights reserved.
#
# U.S. and International Patents Pending.  Duplication or modification
# without prior written consent is strictly prohibited.
#
# U.S. Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Last Updated: 11/20/2003
# Author: Curtis Fields, IBM                            ### cfields@us.ibm.com
################################################################################
#
###################################
#	#### FUNCTIONS ####       #
###################################
#
print_ver()
{
 sep_line
 pr -2 -t -w76 -l1 - << END 
# Date: $RESTORE_DATE
      dr_restore Version: $DR_RESTORE_VER
END
 sep_line
}

########################################################
# Print IBM Patent Information!
########################################################
patent_info()
{
 print "|(c) 1998-2002 International Business Machines Corporation.        |"
 print "| All rights reserved.                                             |"
 print "|                                                                  |"
 print "| U.S. and International Patents Pending.  Duplication or modi-    |"
 print "| fication without prior written consent is strictly prohibited.   |"
 print "|                                                                  |"
 print "| U.S. Government Users Restricted Rights - Use, duplication or    |"
 print "| disclosure restricted by GSA ADP Schedule Contract with IBM Corp.|"
 sep_lin3 
 print ""
}

########################################################
# Version identifier : Returns string : $dr_restore_ver
# Searches within $PATH, finds and replaces old copies of
# dr_restore.sh 
########################################################
#
ver_check()
{
DR_RESTORE_VER=2.56
CHECK=$3
#
 case "$1" in
   snapshot) SNAPSHOT="YES";
   shift;;
   standard) SNAPSHOT="";
   shift;;
   *) SNAPSHOT="";;
 esac

 LATEST_RELEASE=$DR_RESTORE_VER
 pname="$0"
 current_dir=$PWD
 clear

 #### Check and make sure that $0 release level is at least as high as the 
 #### dr_snapshot.sh level
 if [[ -f /usr/sbin/dr_restore.sh ]]; then
  echo "dr_restore.sh found in /usr/sbin" >> $logfile
 else 

  cp $0 /usr/sbin/dr_restore.sh
  if (( $?  != 0 )); then
   echo "Copy of $0 failed to /usr/sbin!"
   echo "Copy of $0 failed to /usr/sbin!" >> $logfile
   echo "Please check /usr filesystem and ensure that at least 65K is free!"
   exit 1
  fi
    chmod 500 /usr/sbin/dr_restore.sh
 fi
 sep_lin3 | tee -a $logfile
 echo "|                    IBM BCRS RDWS DR_RESTORE                      |" | tee -a $logfile
 sep_lin3 | tee -a $logfile
 patent_info
 if [[ $CHECK != check ]]; then
 for i in `echo $PATH|sed s!:!" "!g`
  do
   if [ -f $i/dr_restore.sh ]; then

    dr_snapshot_release=`grep "^DR_RESTORE_VER=" $i/dr_restore.sh`
    if (( $? != 0 )); then     
      dr_snapshot_release="DR_RESTORE_VER=1.1"
    fi

    dr_snapshot_release=`echo $dr_snapshot_release|awk -F"=" '{print $2}'`
    BC_LATEST_RELEASE=`echo "scale=1; 10 * $LATEST_RELEASE" | bc`
    bc_dr_snapshot_release=`echo "scale=1; 10 * $dr_snapshot_release" | bc`

    if [[ ./dr_restore.sh -nt $i/dr_restore.sh ]] \
    || (($BC_LATEST_RELEASE > $bc_dr_snapshot_release)); then

     if [[ -n $SNAPSHOT ]]; then
      echo "FOUND DOWNLEVEL RELEASE in $i"
     else
      echo "FOUND DOWNLEVEL RELEASE in $i" >> $logfile
      ls -l $i/dr_restore.sh >> $logfile
     fi

     if (($BC_LATEST_RELEASE == $bc_dr_snapshot_release)); then
      echo "Replacing Version $dr_snapshot_release with later release date Version $LATEST_RELEASE\n" >> $logfile
     else
      echo "Replacing Version $dr_snapshot_release with Version $LATEST_RELEASE\n" >> $logfile
     fi
     mv -f $i/dr_restore.sh $i/dr_snapshot.old 2>> $logfile
     chmod 400 $i/dr_snapshot.old 2>> $logfile
     cp $0 $i/dr_restore.sh 2>> $logfile
     chmod 500 $i/dr_restore.sh 2>> $logfile
    fi
   fi
    
 done
 fi

 echo "\n" >> $logfile
}

con_tinue()
{
 print "\nWould you like to continue?"
  print "Enter Y/N \c"
   while read input; do
     case $input in
      Y|y) break;;
      N|n) print "\nExiting DR Restore run!\n"
         exit 1;;
      *) ;;
     esac
     printf "Enter Y/N  \a"
   done
}

########################################################
# Waiter line used throughout output
########################################################
waiter2() 
{
 print ".\c"
}

########################################################
# Waiter line used throughout output
########################################################
waiter()
{
 waite[0]="printf "%c" -"; waite[1]="printf "\\b%c" \\"
 waite[2]="printf "\\b%c" |"; waite[3]="printf "\\b%c" /"
 waite[4]="printf "\\b%c" -"; waite[5]="printf "\\b%c" \\"
 waite[6]="printf "\\b%c" |"; waite[7]="printf "\\b%c" /"
 waite[8]="printf "\\b%c" - "; slow=1

 if (( $tmr < 9 )); then
  (( tmr = $tmr + 1 ))
 else
  tmr=0
 fi
 while (( $slow < 9 )); do
  (( slow = slow + 1 ))
 done
 ${waite[$tmr]}

}

########################################################
# Separator line used throughout output
########################################################
#
sep_line()
{
echo "####################################################################"
}

########################################################
# Separator line used throughout output
########################################################
#
sep_lin2()
{
echo "____________________________________________________________________"
}

sep_lin3()
{
echo "--------------------------------------------------------------------"
}


#####################################################################
# Checks for dr_restore.sh version on internal server: 
# (bcrsgai.wma.ibm.com) if down level transfers latest then installs 
#####################################################################
check_for_latest_version()
{

 trap 'rm -f /tmp/versions.txt; exit' 1 2 15

 BCRS_SERVER=bcrsgai.wma.ibm.com
 LATEST_VER=0

 get_latest()
 { 
  cd /$HOME
  print "\nPlease wait, retreiving latest 'dr_restore.sh' version.\n"
  print "machine $BCRS_SERVER" > .netrc
  print "\t login delivery"    >> .netrc
  print "\t password support"  >> .netrc
  print ""                     >> .netrc
  print "macdef latest"        >> .netrc
  print "\t bin"               >> .netrc
  print "\t lcd /tmp"          >> .netrc
  print "\t get install_dr_restore.tar" >> .netrc
  print "\t quit"              >> .netrc
  print "\n"                   >> .netrc
  if [[ -f /.netrc ]]; then
   chmod 600 /.netrc
  fi 
  cd /tmp
  if [[ -f install_dr_restore.tar ]]; then
   rm -f install_dr_restore.tar
  fi
  echo "\$ latest" | ftp $BCRS_SERVER 
  if (( $? == 0 )); then
   cd /tmp
   sep_lin3
   print "Installing 'dr_restore.sh' script."
   tar -xvf /tmp/install_dr_restore.tar 2>/dev/null
   if (( $? == 0 )); then
    cp -f /usr/sbin/dr_restore.sh /$current_dir 
    cp -f /usr/sbin/dr_restore.sh /tmp
   fi
   sep_lin3
  else
    print "\a\nDownload of 'install_dr_restore.tar' FAILED!\n"
  fi
  
 }

 ver_check snapshot check
 sep_lin3
 print "\t\t  CHECKING FOR CURRENT VERSION"
 sep_lin3
 print "\nCurrent running 'dr_restore.sh' version: $DR_RESTORE_VER \n"
 print "Checking for latest version at: $BCRS_SERVER\n"
 cd /$HOME
 if [[ -f .netrc ]]; then
  cp .netrc .netrc.orig
 fi 
 if [[ -f /tmp/versions.txt ]]; then
  mv -f /tmp/versions.txt /tmp/version.orig
 fi
 print "machine $BCRS_SERVER" > .netrc
 print "\t login version"    >> .netrc
 print "\t password check"   >> .netrc
 print ""                    >> .netrc
 print "macdef checkversion" >> .netrc
 print "\t asci"             >> .netrc
 print "\t lcd /tmp"         >> .netrc
 print "\t get versions.txt" >> .netrc
 print "\t quit"             >> .netrc
 print "\n"                  >> .netrc
 print "macdef latest" >> .netrc
 print "\t bin"             >> .netrc
 print "\t get install_dr_restore.tar" >> .netrc
 print "\t quit"             >> .netrc
 print "\n"                  >> .netrc
 if [[ -f .netrc ]]; then
  chmod 600 .netrc
  ping -c 1 $BCRS_SERVER 50 2>/dev/null 1>/dev/null
  if (( $? == 0 )); then
  print "Please wait, retreiving version info now!"
  echo "\$ checkversion" | ftp $BCRS_SERVER 
  if (( $? == 0 )); then
   if [[ -f /tmp/versions.txt ]]; then
    LATEST_VER=`awk ' /^dr_restore.sh/ {print $0}' /tmp/versions.txt |\
    awk -F":" '{print $2}'`
    print "\nChecking current version against latest version\n"
    sep_lin3
    print "Current version: $DR_RESTORE_VER"
    print "Latest version: $LATEST_VER"
    sep_lin3
    if (( $(echo "scale=1; $LATEST_VER * 100" | bc) > $(echo "scale=1; $DR_RESTORE_VER * 100" | bc) )); then
      print "\a\nLater version available, would you like to download and install it now?"
     print "\nEnter Y/N \c"
     while read input; do
      case $input in
      Y|y) get_latest
           break;;
      N|n) print "\nExiting DR Restore run!\n"
         exit 1;;
      *) ;;
      esac
     printf "Enter Y/N  \a"
     done

    else
     print "\nCurrently at latest release level!\n"
     rm -f /tmp/versions.txt
     rm -f /.netrc
    fi
    
    print "\nTransfer complete!\n"
    rm -f /tmp/versions.txt
   fi

   if [[ -f /.netrc.orig ]]; then
    mv /.netrc.orig /.netrc
   else
    rm -f /.netrc
   fi 
  fi 

  else
   print "\aNot on the IBM Internal network!\n"
   exit 1
  fi

 else
  print "Error!  Could not find .netrc files!"
  exit 1
 fi

}

#####################################################################
# Checks for DR Restore files, verifies that they are the output from
# DR_SNAPSHOT.  Returns string : $rebuild_files 
#####################################################################
#
check_files()
{
 VERIFY=$1  ### IF VERIFY_ALL ROUTINE - LOGFILE CHANGES TO - 'Verify.log'

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRDIR$INFILE.file_check; exit' 1 2 15

 if [[ $VERIFY = YES ]]; then
  export logfile=$DRRSTDIR/Verify.$RESTORE_DATE.log
 fi

 rebuild_files=""

 host_name=`hostname`
 SYSTEM=`echo $host_name | tr 'a-z' 'A-Z'`

 #### CHECK FOR FILE 'DR_SNAP' DATE
 get_restore_date()
 { 
  REST_DATE=0
  TMP_DATE=""
  REST_DATE=$RESTORE_DATE
 
  if [[ -f $FN ]]; then
   SNAP_DATE=`egrep "^# Date:" $FN | awk '{print $3}'`
   print "SNAPSHOT DATE: $SNAP_DATE"
   print "RESTORE DATE:  $REST_DATE\n"
  else
   print "\aDR_Snapshot files 'MUST' contain a 'SNAPSHOT DATE'!" 
   print "Check snaphot file and re-run 'dr_restore.sh'"
   exit 1
  fi
 }

 #### Critical Files Needed for Rebuild
 #### *.rdws,*.commands,*.rebuild,*.long_listing,*.user.tar, <hostname>.<date>
 check_critical()
 { 
 
  case "$1" in
   snapshot) SNAPSHOT="YES"; shift;;
   *) SNAPSHOT="" ;;
  esac
 
  FN=`cat /tmp/EXTRACT.$RESTORE_DATE|awk '{print $2}'|sed -es!","!""!g|egrep -v "\.Z|\.nfs|\.df|\.rdws|\.sdr|\.tar|\.settings|\.errpt|\.log|\.long_listing|\.ess|\.rebuild|\.commands|\.ssa|\.HACMP_conf|\.bin|\.BIN|\.TARFILE|\.hageo|\.exclude|\.sh|\.out|\.restore|\.tarfile"`
  
  if [ $? -eq 0 ]; then 
   if [ -n $FN ]; then
    print "FOUND $FN" | tee -a $logfile
   else
    print "WRONG FORMAT\a" | tee -a $logfile
    print "Information File Must Be Present To Continue" | tee -a $logfile
    exit 1
   fi
  else
   print "WRONG FORMAT\a" | tee -a $logfile
   exit 1
  fi
 
  CMDS=`ls $FN.commands 2>/dev/null`
  if [ $? -eq 0 ]; then 
    print "FOUND $CMDS" | tee -a $logfile
  else
    print "WRONG FORMAT\a" | tee -a $logfile
    print "Information File '$FN.commands' Must Be Present To Continue" | tee -a $logfile
    exit 1
  fi
  RBLD=`ls $FN.rebuild 2>/dev/null`
  if [ $? -eq 0  ]; then 
   print "FOUND $RBLD" | tee -a $logfile
   DR_SNAP_VER=`awk -F":" ' / dr_snapshot.sh Version: / {print $3}' $RBLD`
   DR_SNAP_VER=`echo $DR_SNAP_VER`

   if [[ ! -n `echo "$DR_SNAP_VER" | awk ' /[0-9]/ {print $0}'` ]]; then
    DR_SNAP_VER=240  ## OLD VERSION OF SNAPSHOT TOOL
    print "\nWARNING!! Old version of dr_snapshot.sh tool used to capture config!" | tee -a $logfile
    print "\nPlease have your BCRS customer pull down the latest release from: \n"|tee -a $logfile
    sep_lin3 | tee -a $logfile
    print "\nhttps://www-1.ibm.com/services/continuity/recover2.nsf/connect/Customer+connect\n" | tee -a $logfile
    print "Click on the 'Requirements Definition Work Sheet (RDWS)' link\n"
    print "userid: customerconnect" | tee -a $logfile
    print "passwd: delivery\n" | tee -a $logfile
    sep_lin3 | tee -a $logfile
    con_tinue
   else
    DR_SNAP_VER=$(echo "scale=1; $DR_SNAP_VER * 100" | bc)
   fi

  else
   print "WRONG FORMAT\a" | tee -a $logfile
   print "Information File '$FN.rebuild' Must Be Present To Continue" | tee -a $logfile
   exit 1
  fi
  LLST=`ls $FN.long_listing 2>/dev/null`
  if [ $? -eq 0  ]; then 
    print "FOUND $LLST" | tee -a $logfile
  else
    print "WRONG FORMAT\a" | tee -a $logfile
    print "Information File '$FN.long_listing' Must Be Present To Continue" | tee -a $logfile
    exit 1
  fi
  USR=`ls $FN.user.tar 2>/dev/null`
  if [ $? -eq 0 ]; then 
    print "FOUND $USR\n" | tee -a $logfile
  else
    print "WARNING! POSSIBLE WRONG FORMAT\a" | tee -a $logfile
    print "Information File '$FN.user.tar' not found!" | tee -a $logfile
    print "This File May Be Needed To Rebuild System Correctly!" | tee -a $logfile
  fi
  NTWRK=`ls $FN.NET.settings 2>/dev/null`
  if [ $? -eq 0 ]; then 
    print "FOUND $NTWRK\n" | tee -a $logfile
  else
    print "WARNING! POSSIBLE WRONG FORMAT\a" | tee -a $logfile
    print "Information File '$FN.net.settings' not found!" | tee -a $logfile
    print "This File May Be Needed To Rebuild System Correctly!" | tee -a $logfile
  fi
 }
 
 if [[ -n $SNAPSHOT ]]; then
  echo "Checking for DR_RESTORE input files!"
 fi

 echo "Checking for DR_RESTORE input files!" >> $logfile
 sep_line >> $logfile

  if [[ ! -f $DRDIR$INFILE ]]; then
     echo "INFILE: $INFILE NOT FOUND"
     echo "INFILE: $INFILE"
     print "INPUT FILE DOES NOT EXIST!  Searching for additional input files!\n" | tee -a $logfile

     if [[ ! -d $DRDIR ]]; then
      echo "DRDIR: $DRDIR"
      print "INPUT DIRECTORY DOES NOT EXIST! Please verify input directory!\n" | tee -a $logfile
      print "$USAGE"
      print "$USAGE" >> $logfile
      print "\t\t\t - or - \n" | tee -a $logfile
      print "If no directory or file are supplied then DR_RESTORE assumes '/tmp/drinfo'\n" | tee -a $logfile

      print "Trying the /tmp/drinfo directory!" | tee -a $logfile
      DRDIR=/tmp/drinfo

      if [[ ! -d /tmp/drinfo ]]; then
        print "No DR_RESTORE/REBUILD files found in /tmp/drinfo!\n" | tee -a $logfile
        print "Begin looking in /tmp!\n" | tee -a $logfile
        DRDIR=/tmp/
      fi
     fi

     #### Look for DR_SNAPSHOT files in /tmp/drinfo
     rebuild_files=`ls $DRDIR| egrep ".Z|.RDWS.BIN|.tar|.TAR|.rdws.bin|.z"` 2>/dev/null
     if [[ -n `echo "$rebuild_files" | grep -i "user.tar"` ]]; then
      rebuild_tmp=`echo "$rebuild_files" | egrep -iv "user.tar"`
      rebuild_files=$rebuild_tmp
     fi
     if [[ -n $rebuild_files ]]; then
      print "FOUND possible DR_SNAPSHOT files in $DRDIR!  " | tee -a $logfile
      print "Will try to anylyze them!\n"
      sep_line
     else
     DRDIR=/tmp/
     rebuild_files=`ls $DRDIR|egrep ".Z|.RDWS.BIN|.tar|.TAR|.rdws.bin|.z" | egrep -v ".out|.log|.err"| awk '/^[A-Z,a-z,0-9].[A-Z,a-z,0-9]/ {print $0}'` 2>/dev/null
      if [[ -n $rebuild_files ]]; then
       print "FOUND possible DR_SNAPSHOT files in $DRDIR!  " | tee -a $logfile
       print "Will try to anylyze them!\n"
       sep_line
      fi

     fi
  fi

 cd $DRDIR 
  if [[ -f `echo $INFILET` ]]; then
   rebuild_file=$INFILET
  else

  #### CHECK FOR $MACHINE FILES ENDING W/ .Z,.RDWS.BIN,.tar
  rebuild_files=`ls $DRDIR| egrep ".Z|.RDWS.BIN|.tar|.TAR|.rdws.bin|.z"` 2>/dev/null
  if [[ -n `echo "$rebuild_files" | grep -i "user.tar"` ]]; then
   rebuild_tmp=`echo "$rebuild_files" | egrep -iv "user.tar"`
   rebuild_files=$rebuild_tmp
  fi

  if [[ ! -n $rebuild_files ]]; then
   print "NO DR_RESTORE/REBUILD FILES FOUND!\n"
   print "Verify that directory $DRDIR has 'dr_snapshot.sh' output files\n">>$logfile
   print "Output files must be in 'dr_snapshot.sh format and end with *.Z, *.RDWS.BIN, or *.tar\n" >> $logfile
   print "NO DR_RESTORE/REBUILD FILES FOUND!\n" >> $logfile
   print "Verify that directory $DRDIR has 'dr_snapshot.sh' output files\n"
   print "Output files must be in 'dr_snapshot.sh format and end with *.Z, *.RDWS.BIN, or *.tar\a\n"
   exit 1
  fi

  ### FOUND FILES
  found_file=""
  for j in $rebuild_files;
  do
   echo $j | grep -i $SYSTEM 1>/dev/null 2>/dev/null
   if [ $? -eq 0 ]; then
    found_file="$found_file \n$j"
   fi
  done
 
 if [[ -n $found_file ]]; then
  print "Current System Name: $SYSTEM\n"
  print "NOTE!  RDWS FILES THAT CONTAIN THE CURRENT HOSTNAME:"
  print "$found_file\n"
  sep_line
 fi
  print "Files found in $DRDIR:\n"

  #### Select One of Multiple Files Found
  files=$rebuild_files
  select_num=0
 
  for i in $files
  do
  (( select_num = $select_num + 1 ))
  names[$select_num]="$i" 
  echo "$select_num. $i"
  done
 
  print "\nPlease make one selection!  Or [Q-Quit]\n"
  print ">\c" 
  while read select_file; do
  y=0
   case $select_file in
    +([0-9])) 
     if (( $select_file <= $select_num )); then
      print "\nFile: ${names[$select_file]}"
      print "Is this correct?  [Y/N] or [Q-Quit] \c"
      while read answer; do
       case $answer in
 	Y|y) rebuild_file=${names[$select_file]}
         FILEFEED=NO
         clear
 	break ;;
   	N|n) rebuild_file=""; break ;;
   	Q|q) exit 1 ;;
         *) ;;
       esac
      print "Enter [Y/N or [Q] \c"
     done
     else
     print_ver
     print ""
     print "Must be from 1 to $select_num or [Q-Quit]!\n"
     print "Please must make a valid selection!"
     sep_lin3
     select_num=0
     for i in $files
     do
      (( select_num = $select_num + 1 ))
      names[$select_num]="$i"
      echo "$select_num. $i"
     done
     fi ;;
    Q|q) exit 1 ;;
    *) print "Enter a number please!" ;;
   esac
  if [[ -n $rebuild_file ]]; then
   break
  else
     clear
     print_ver
     print ""
     print "Must be from 1 to $select_num or [Q-Quit]\n"
     print "Please must make a valid selection!"
     sep_lin3
     select_num=0
     for i in $files
     do
      (( select_num = $select_num + 1 ))
      names[$select_num]="$i"
      echo "$select_num. $i"
     done
 
  fi 
  done
 
  fi

 ### CHECK FOR $MACHINE FILES ENDING W/ .Z,.BIN,.rebuild,.$SNAPDATE,.commands
 cd $DRDIR
 for i in $rebuild_file; do
 case $i in
    *.Z)
         if [[ $SNAPSHOT = YES ]]; then
          if [[ $FILEFEED = NO ]]; then 
          print_ver
          fi
         fi
         if [[ $FILEFEED = NO && $SNAPSHOT != YES ]]; then 
          print_ver
         fi
         echo "DIR: $DRDIR"
	 echo "INFILE: $i"
	 zcat $DRDIR/$i |tar -xvf - 2>/dev/null 1>/tmp/EXTRACT.$RESTORE_DATE
         if [ $? != 0 ]; then
	  echo "$i not in correct format"
		exit 1
   	 else
          print "Un-tarring $i" 
	  print "Checking for required extensions!\n"
          check_critical
   	 fi 
	break ;;
    *.bin.z)  
         if [[ $SNAPSHOT = YES ]]; then
          if [[ $FILEFEED = NO ]]; then 
          print_ver
          fi
         fi
         if [[ $FILEFEED = NO && $SNAPSHOT != YES ]]; then 
          print_ver
         fi
         echo "DIR: $DRDIR"
	 echo "INFILE: $i"
         ## RENAME to *.Z
         INFILE_TMP=`echo "$i" | awk -F"." '{print $1"."$2"."$3"."$5"."$6"."$7".Z"}'`
         mv $i $INFILE_TMP
         i=$INFILE_TMP
         
	 zcat $DRDIR/$i |tar -xvf - 2>/dev/null 1>/tmp/EXTRACT.$RESTORE_DATE
         if [ $? != 0 ]; then
	  echo "$i not in correct format"
		exit 1
   	 else
          print "Un-tarring $i" 
	  print "Checking for required extensions!\n"
          check_critical
   	 fi 
	break ;;
    *.RDWS.BIN|*.rdws.bin) 
         if [[ $SNAPSHOT = YES ]]; then
          if [[ $FILEFEED = NO ]]; then 
          print_ver
          fi
         fi
         if [[ $FILEFEED = NO && $SNAPSHOT != YES ]]; then 
          print_ver
         fi
         echo "DIR: $DRDIR"
	 echo "INFILE: $i"
	 # get_restore_date
	 tar -xvf $DRDIR/$i 2>/dev/null 1>/tmp/EXTRACT.$RESTORE_DATE
         if [ $? != 0 ]; then
	  echo "$i not in correct format"
  	  exit 1
         else
	  print "Checking for required extensions!\n"
          check_critical
   	 fi 
         break ;;

    *.tar|*.TAR|*.TARFILE|*.tarfile) 
         if [[ $SNAPSHOT = YES ]]; then
          if [[ $FILEFEED = NO ]]; then 
          print_ver
          fi
         fi
         if [[ $FILEFEED = NO && $SNAPSHOT != YES ]]; then 
          print_ver
         fi
         echo "DIR: $DRDIR"
	 echo "INFILE: $i"
	 get_restore_date
	 tar -xvf $DRDIR/$i 2>/dev/null 1>/tmp/EXTRACT.$RESTORE_DATE
         if [ $? != 0 ]; then
	  echo "$i not in correct format"
  	  exit 1
         else
	  print "Checking for required extensions!\n"
          INFILE=`cat /tmp/EXTRACT.$RESTORE_DATE | awk '{print $2}'|sed -es!","!""!g`
          check_critical
   	 fi 
         break ;;
 esac
    echo "No usable files found!"
	exit 1
 done
	 get_restore_date

print "FOUND ALL CRITICAL FILES.  CONTINUING REBUILD"| tee -a $logfile

}

####################################################################
#### Checks for old PVIDs on installation disks
####################################################################
clear_ids() 
{
 for j in $old_vgpvs; do
  if [ `echo $j | awk -F"." '{print $2}'` != "none" ]; then
   chdev -l `echo $j | awk -F"." '{print $1}'` -a pv=clear 2>/dev/null 1>/dev/null
   if [ $? = 0 ]; then
    print "Clearing PVID on `echo $j | awk -F"." '{print $1}'" | tee -a $logfile
   else
    print "Problems with `echo $j | awk -F"." '{print $1}'` please fix manually"
   fi
  fi
 done
}

check_vgpv()
{

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 old_vgpvs=`lspv | awk '{print $1"."$2"."$3}' | grep -i None`
 if [[ -n `echo "$old_vgpvs" | awk -F"." ' !/none/ {print $2}'` ]]; then

 sep_line
 print "Checking for old Volume Group(s) PV IDs."
 for i in $old_vgpvs; do
  if [ `echo $i | awk -F"." '{print $2}'` != "none" ]; then
   print "\nOld Volume Group(s) PV IDs have been found!  Would you like to"
   print "clear the hdisk PV IDs?\n"
   print "Enter Y/N \c"
   while read input; do
     case $input in
      Y|y) print "\n"
           clear_ids
           break 2 ;;
      N|n) print "\nIgnoring the old VG/PV IDs!  Will try to over-write with new VG information!" 
           if [[ $SNAPSHOT = YES ]]; then
            con_tinue
           fi
           break 2 ;;
      *)   ;;
     esac
     printf "Enter Y/N  \a"
    done
  fi
 done

 fi

}

####################################################################
#### Verifies that USER INFORMATION is needed to rebuild
#### /etc/passwd,group /etc/security/passwd,group,user
#### Changes password to 'support'
#### Also check max number of process allowed
####################################################################
find_user() 
{
 OLD_PASSWD=""
 ### root:passwd = encrypted password 'support'
 NEW_PASSWD="YM/0lK.Lus7vY"

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f /tmp/PASSWORD; break' 1 2 15

 if [[ -n $USR ]]; then 
  clear
  print_ver
  sep_line >> $logfile
  print "Verifying that USER Information is needed for 'REBUILD'.\n"|tee -a $logfile
  cd $DRDIR
  if [[ $SNAPSHOT = YES ]]; then
   print "\nChecking /etc/passwd, /etc/group files!  If the 'RDWS' files are" | tee -a $logfile
   print "different, then 'RDWS' files will be copied to the system and the"|tee -a $logfile
   print "'root' password will be changed to 'support'.\n" | tee -a $logfile
  else
   print "\nChecking for USER files!\n" | tee -a $logfile
  fi
  tar -xvf $USR 2>>$DRRSTDIR/REBUILD.ERRORS 1>/dev/null
  if [ $? != 0 ]; then
   print "\nProblems extracting $USR!  Please check $DRRSTDIR/REBUILD.ERRORS!" | tee -a $logfile
   break
  fi
  if [[ -f $DRDIR/etc/passwd ]]; then
   if [[ `ls -l $DRDIR/etc/passwd| awk '{print $5}'` != `ls -l /etc/passwd | awk '{print $5}'` ]]; then
    cp -pr /etc/passwd /etc/passwd.orig
    cp -pr $DRDIR/etc/passwd /etc/passwd
    cp -pr /etc/group /etc/group.orig
    cp -pr $DRDIR/etc/group /etc/group
    cp -pr /etc/security/passwd /etc/security/passwd.orig
    cp -pr $DRDIR/etc/security/passwd /etc/security/passwd
    cp -pr /etc/security/group /etc/security/group.orig
    cp -pr $DRDIR/etc/security/group /etc/security/group
    cp -pr /etc/security/user /etc/security/user.orig
    cp -pr $DRDIR/etc/security/user /etc/security/user

    egrep -p "^root:" /etc/security/passwd > /tmp/PASSWD
    OLD_PASSWD=`awk ' /password = / {print $3}' /tmp/PASSWD`

    ### REPLACE ROOT LOGIN/RLOGIN = TRUE VIA SED
    cp -pr /etc/security/user /etc/security/user.rdws
    print "/^root:/ {" > $DRRSTDIR/replace.sed
    print ":loop" >> $DRRSTDIR/replace.sed
    print "s/login = false/login = true/g" >> $DRRSTDIR/replace.sed
    print "\$!{" >> $DRRSTDIR/replace.sed
    print "N" >> $DRRSTDIR/replace.sed
    print "/\\\n\c" >> $DRRSTDIR/replace.sed
    print "\$/!b loop" >> $DRRSTDIR/replace.sed 
    print "} " >> $DRRSTDIR/replace.sed
    print "} " >> $DRRSTDIR/replace.sed
    sed -f $DRRSTDIR/replace.sed /etc/security/user.rdws > /etc/security/user
    rm -f $DRRSTDIR/replace.sed /etc/security/user.rdws

    if [[ -n $OLD_PASSWD ]]; then
     print "Changing root passwd to 'support'." | tee -a $logfile
     if [[ $SNAPSHOT != YES ]]; then
     sleep 4
     fi
     cp -pr /etc/security/passwd /etc/security/passwd.orig

     ## CHECK FOR '/' character in passwd
     if [[ -n `echo "$OLD_PASSWD" | egrep "\/"` ]]; then
      sed -es!"`echo "$OLD_PASSWD" | sed -es!"\\/"!"\\\/"!g`"!"$NEW_PASSWD"!g /etc/security/passwd.orig > /etc/security/passwd
     else
      sed -es!"$OLD_PASSWD"!"$NEW_PASSWD"!g /etc/security/passwd.orig > /etc/security/passwd
     fi

     print "\nRe-indexing 'passwd' and 'group' files!" | tee -a $logfile
     mkpasswd -c 2>/dev/null 1>/dev/null
     if [ $? != 0 ] ;then
      mkpasswd -d
     fi
    fi
   fi
  fi
 else
  print "\nUser Information was not found with this RDWS file!\n" | tee -a $logfile
 fi
 ### CHECK FOR MAX PROCESSES
 if [[ -n $CMDS ]]; then
  MAXPROC=`awk ' /^chdev / {print $5}' $CMDS | awk -F"=" '{print $2}'` 
  if [[ -n $MAXPROC ]]; then
   print "\nChecking for 'MAXPROCESSES' allowed for the system.\n" | tee -a $logfile
   max_procs=`lsattr -El sys0 -a maxuproc|awk '{print $2}'`
   if (( $MAXPROC != $max_procs )); then
    print "Changing MAX PROCESSESS to: $MAXPROC" | tee -a $logfile
    print "chdev -l sys0 -a maxuproc=$MAXPROC" | tee -a $logfile
    if [[ $CMDSO != YES ]]; then
    chdev -l sys0 -a maxuproc=$MAXPROC 2>/dev/null 1>/dev/null
    fi
   fi
  fi 
 fi
 ### CHECK FOR CSS0 INTERFACE CHANGE TO MAX FOR SP SWITCH
 if [[ -n $NTWRK ]]; then
  CSS=`awk ' /^INTERFACE css/ {print $0}' $NTWRK`
  if [[ -n $CSS ]]; then
   if [ -a /dev/css0 ]; then 
   print "\nChecking CSS Interface settings"|tee -a $logfile
   print "Current Sizes:"
   awk ' /^spoolsize / {print $1 "=" $2}' $NTWRK >> $logfile
   awk ' /^rpoolsize / {print $1 "=" $2}' $NTWRK >> $logfile
   current_rpool=`lsattr -El css0|grep rpoolsize|awk '{print $2}'`
   current_spool=`lsattr -El css0|grep spoolsize|awk '{print $2}'`
   if [[ -n $current_rpool && -n $current_spool ]]; then
   if (( $current_rpool != 16777216 || $current_spool != 16777216 )); then
   print "Changing CSS Interface:"
   print "chgcss -l css0 -a spoolsize=16777216"  >> $logfile
   print "chgcss -l css0 -a rpoolsize=16777216"  >> $logfile
   /usr/lpp/ssp/css/chgcss -l css0 -a spoolsize=16777216 2>/dev/null 1>/dev/null
   /usr/lpp/ssp/css/chgcss -l css0 -a rpoolsize=16777216 2>/dev/null 1>/dev/null
   fi
   fi
   fi
  fi 
 fi

}

####################################################################
#### Returns:  $total_dasd_needed, $tot_dasd
####################################################################
find_dasd() 
{
 tot_dasd=0
 dasd=0
 actual_hdd_cnt=0
 previs_hdd_cnt=1
 vpath_DASD=""
 ess_2105=""
 lsess_2105=""
 nonpemc=""
 hdd=0

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -rf $DRRSTDIR/DISKS_AVAIL.$$ $DRRSTDIR/DISKS_AVAIL.1$$ $DRRSTDIR/DASD_FOUND.$RESTORE_DATE $DRRSTDIR/ESS2105_DASD.$$ $DRRSTDIR/ESS2105_DASD1.$$ /tmp/lsess.out.lunid.$$ /tmp/ess_device.lunid.$$ $DRRSTDIR/LSPV.DASD.$RESTORE_DATE; exit' 1 2 15

 clear
 print_ver
 sep_line >> $logfile
 print "Verifying that enough RAW DASD is available for 'REBUILD'.\n"|tee -a $logfile

 DASD_FOUND=`lsdev -Cc disk` 

 ### MAP DASD TO SSA/SSARAID/SCSI/SHARK/VPATH/EMC/POWERPATH
 dasd_identify()
 { 
 case "$1" in
  SSARAID) SSARAID="FIND"; shift;;
  *) SSARAID="NONE" ;;
 esac

 ## MAPPING DASD
 print "\n\nPlease wait!  Mapping DASD\n"

  if [[ $SSARAID = FIND ]]; then
  DASD_FOUND=`lsdev -Cc disk` 

  for i in `echo "$DASD_FOUND" | awk ' /SSA||Available/ {print $1":"$4}'`; do 
   disk_name=`echo "$i"| awk -F":" ' {print $1}'`
   disk_type=`echo "$i"| awk -F":" ' {print $2}'`
   waiter2

    if ( echo $disk_type|grep SSA 2>/dev/null 1>/dev/null ); then
     ## SSA DASD
     if [ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]; then
      if [[ -n `awk ' /'$disk_name' / {print $0}' $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE` ]]; then
       waiter2
       disk_attr=`lsattr -El $disk_name|awk ' /size_in_mb/ {print $0}'|awk '{print $2}'`
       hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSARAID"
       (( hdd = $hdd + 1 ))
      else
       waiter2
       disk_attr=`lsattr -El $disk_name|awk ' /size_in_mb/ {print $0}'|awk '{print $2}'`
       hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSA"
       (( hdd = $hdd + 1 ))
      fi
     else
      waiter2
      disk_attr=`lsattr -El $disk_name|awk ' /size_in_mb/ {print $0}'|awk '{print $2}'`
      hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSA"
      (( hdd = $hdd + 1 ))
     fi
    fi
  done

  else

  for i in `echo "$DASD_FOUND"|awk ' /Available/ {print $1":"$4":"$5":"$6":"$7":"$8}'`; do
  disk_name=`echo "$i"| awk -F":" ' {print $1}'`
  disk_type=`echo "$i"| awk -F":" ' {print $2":"$3":"$4":"$5":"$6}'`

  if [ `echo "$disk_name"|awk ' /^hdisk|^vpath|^hdiskpower/ {print $0}'` ]; then         
   waiter
 
    if ( echo $disk_type|grep SSA 2>/dev/null 1>/dev/null ); then
     ## SSA DASD
     if [ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]; then
      if [[ -n `grep "$disk_name " $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE` ]]; then
       disk_attr=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
       hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSARAID"
       (( hdd = $hdd + 1 ))
      else
       disk_attr=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
       hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSA"
       (( hdd = $hdd + 1 ))
      fi
     else
      disk_attr=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
      hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSA"
      (( hdd = $hdd + 1 ))
     fi
#      
     else if ( echo  $disk_type|egrep "IBM:FC:2105|IBM:2105" 2>/dev/null 1>/dev/null ); then
      ## ESS HDISK DASD
      disk_attr=`echo "$ess_config"|egrep "^$disk_name:"|awk -F":" '{print $2}'`
      ## CHECK AND MAKE SURE THE HDD DOESN'T BELONG TO A VPATH
      if [[ -z `echo "$ess_vpath_disks"|awk ' /'$disk_name' / {print $0}'` ]]; then
       hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:ESS2105"
       (( hdd = $hdd + 1 ))
      fi
 
     else if [ `echo  $disk_name | grep "^vpath"` ]; then      ## ESS DASD
      if [[ -f /tmp/vpath_config.tmp ]]; then
       disk_attr=`awk -F"@" '/'$disk_name'@/ {print $2}' /tmp/vpath_config.tmp`
       if [[ -n $disk_attr ]]; then
        hdd_avail[$hdd]="$disk_name:$disk_attr:vpath:ESSVPATH"
        (( hdd = $hdd + 1 ))
       fi
      fi
 
     else if [ `echo  $disk_name | grep "^hdiskpower"` ]; then     
      ## EMC DASD
      if [[ -f $DRRSTDIR/EMC_DASD.$RESTORE_DATE ]]; then
       disk_size=0
       disk_attr=`awk -F":" ' /^'$disk_name' :/ {print $3}' $DRRSTDIR/EMC_DASD.$RESTORE_DATE | sed -es!":"!""!g`
       if [[ -n $disk_attr ]]; then
        (( disk_size = $disk_attr / 1024 ))
        hdd_avail[$hdd]="$disk_name:$disk_size:powerpath:EMC"
        (( hdd = $hdd + 1 ))
       fi
      fi

     else if [ `echo  $disk_type | egrep "Other:FC:SCSI:Disk|Other:SCSI:Disk"` ]; then
      ## POSSIBLE EMC DASD W/O PowerPath
      if [[ -f $DRRSTDIR/EMC_OTHER.$RESTORE_DATE ]]; then
       disk_size=`awk -F":" ' /^'$disk_name':/ {print $2}' $DRRSTDIR/EMC_OTHER.$RESTORE_DATE`
       hdd_avail[$hdd]="$disk_name:$disk_size:hdisk:EMC"
       (( hdd = $hdd + 1 ))
      fi

     else if ( echo $disk_type|grep SCSI 2>/dev/null 1>/dev/null ); then
      ## SCSI DASD
      disk_attr=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
      hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SCSI"
      (( hdd = $hdd + 1 ))
       
     fi
     fi
     fi
     fi
     fi
    fi
    fi
    done 

    if [[ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]]; then
    ### LOOK FOR Hot Spares!  Throws off total size if not included!
     spare_pdisks=`grep spare $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE | awk '{print $1":"$5}'`
     if [[ -n $spare_pdisks ]]; then
      for j in $spare_pdisks; do
       disk_name=`echo $j | awk -F":" '{print $1}'`
       disk_attr=`echo $j | awk -F":" '{print $2}' | sed -es!GB!""!g`
        if [[ -n $disk_attr ]]; then
         disk_attr=`echo "scale=0; $disk_attr * 1000" | bc`
         hdd_avail[$hdd]="$disk_name:$disk_attr:hdisk:SSARAID-SPARE"
         (( hdd = $hdd + 1 ))
        fi
       done
      fi 
     fi 

  fi
  print ""
 }

 ### CHECK TO SEE IF NEW DRIVES HAVE BEEN ADDED!
 if [[ -f $DRRSTDIR/DASD_FOUND.$RESTORE_DATE ]]; then
  if [[ -n `grep ESSVPATH $DRRSTDIR/DASD_FOUND.$RESTORE_DATE` ]]; then
   ### LOOK FOR ADDED 2105 DASD
   vpath_count=`cat $DRRSTDIR/DASD_FOUND.$RESTORE_DATE |egrep ":vpath:" |wc -l`
   actual_vpath=`lspv | egrep "^vpath" |wc -l`
   vpath_count=`echo $vpath_count`
   actual_vpath=`echo $actual_vpath`
   if (( $vpath_count == $actual_vpath )); then
    dasd_2105=`echo "$DASD_FOUND"|egrep -v vpath|egrep 2105|egrep "Available"|wc -l`
   fi
  fi
  actual_hdd_cnt=`lspv | wc -l`
  if [[ -n $dasd_2105 ]]; then
   actual_hdd_cnt=`echo $actual_hdd_cnt`
   (( actual_hdd_cnt = $actual_hdd_cnt - $dasd_2105 ))
  fi
  previs_hdd_cnt=`egrep -v "SSARAID-SPARE" $DRRSTDIR/DASD_FOUND.$RESTORE_DATE| wc -l`
  actual_hdd_cnt=`echo $actual_hdd_cnt`
  previs_hdd_cnt=`echo $previs_hdd_cnt`
 fi

 if (( $actual_hdd_cnt != $previs_hdd_cnt )); then
  ### QUERY RECOVER DISKS
  print "\nPlease wait!  Querying recovery DASD!\n"
  hdd=0

  ### CHECK FOR EMC SOFTWARE/HARDWARE
  emc_qcount=0
  emc_actual=40000
  emc_devices=`echo "$DASD_FOUND"  | egrep "EMC "| grep Available`
  emc_powerpt=`echo "$DASD_FOUND" | grep "^hdiskpower" | grep Available`
  emc_inqtool=`lslpp -l | grep EMCpow`
  if [[ -n $emc_devices && -n $emc_powerpt ]]; then
   print "Found EMC DASD!\n"
   emc_devices=""; found_emc=""
   if [[ -f $DRRSTDIR/EMC_DASD.$RESTORE_DATE ]]; then
    emc_qcount=`wc -l $DRRSTDIR/EMC_DASD.$RESTORE_DATE | awk '{print $1}'`
    emc_actual=`echo "$emc_powerpt" | wc -l`
   fi

   ### EMC Utils MUST BE INSTALLED TO QUERY SYMMETRIX POWER DISKS
   inq_path="/usr/bin/"
   if (( $emc_qcount != $emc_actual )); then
    # CHECK FOR MULTIPLE 'inq' tools, look for '/usr/bin/inq' first
    if [[ ! -f /usr/bin/inq ]]; then
     inq_path=`find /usr -name "inq" -print`
     inq_number=`echo "$inq_path" |wc -l`
     inq_number=`echo $inq_number`
     if (( $inq_number > 1 )); then
      for q in $inq_path; do
       if [[ -f $q ]]; then
        inq_path_tmp=`echo "$q" | sed -es!"\/inq"!"/"!g`
        if [[ -f ${inq_path_tmp}inq ]]; then
         break;
        fi
       fi
      done
     else
      inq_path_tmp=`echo "$inq_path" | sed -es!"\/inq"!"/"!g`
     fi

     if [[ -f ${inq_path_tmp}inq ]]; then
      inq_path="${inq_path_tmp}"
     else
      inq_path=""
     fi
    fi
     
    if [[ -n $inq_path ]]; then
     inq_path=`echo "$inq_path" | sed -es!"\/inq"!"/"!g`
     export PATH="$PATH:$inq_path:"
    else
     print "The EMC Utils must be in \$PATH!"
     print "Please udate \$PATH to EMC query tool 'inq'!"
     exit 1
    fi

    found_emc=`which ${inq_path}inq 2>/dev/null`

    if [[ -f $found_emc ]]; then
     inq_path=$found_emc
     $inq_path -f_powerpath | awk ' /^\/dev/ {print $0}' | awk '{print $1,$5,$6}' | sed -es!"/dev/r"!""!g > $DRRSTDIR/EMC_DASD.$RESTORE_DATE
     print "\n\nCompleted Query of EMC DASD\n"
    else
     print "EMC Symmetrix Query Tools 'NOT' found in \$PATH!" | tee -a $logfile
     print "Looking in /usr\n" | tee -a $logfile
     if [[ -f /usr/inq ]]; then
      cd /usr
      ./inq -f_powerpath | awk ' /^\/dev/ {print $0}' | awk '{print $1,$5,$6}' | sed -es!"/dev/r"!""!g > $DRRSTDIR/EMC_DASD.$RESTORE_DATE
      print "\nCompleted Query of EMC\n"
      cd $DRDIR
     else
      print "EMC Symmetrix Query Tools 'NOT' found!" | tee -a $logfile
     fi
    fi

   fi
  fi

  ### CHECK FOR EMC NON-POWERPATHED DASD
  nonpemc=`echo "$DASD_FOUND" | egrep "Other FC SCSI Disk|Other SCSI Disk"| grep Available`
  if [[ -n $nonpemc ]]; then
   print "Found possible non-powerpath EMC DASD!\n"
   print "1. Would you like to walk each disk and verify it's size?  SLOW... "
   print "2. Walk one 'Other SCSI Disk' and assign size to all remaining disk(s).  FAST..." 
   print "\nPlease enter 1, 2, or I for ignore!\n" 
   print ">\c" 
   while read input; do
     case $input in
      1) if [[ -f $DRRSTDIR/EMC_OTHER.$RESTORE_DATE ]]; then
          emc_count=`wc -l $DRRSTDIR/EMC_OTHER.$RESTORE_DATE | awk '{print $1}'`
         else 
          emc_count=0
         fi 

         if (( $emc_count != `echo "$nonpemc" | wc -l | awk '{print $1}'` )); then 
         rm -f $DRRSTDIR/EMC_OTHER.$RESTORE_DATE
         lspv > $DRRSTDIR/LSPV.DASD.$RESTORE_DATE 

         print "\nIdentifying unknown DASD device(s)!\n" | tee -a $logfile 
         for i in `echo "$nonpemc"|egrep "Other FC SCSI Disk|Other SCSI Disk"|awk '{print $1}'`
          do
          other_size=""
          if [[ -n `egrep "$i " $DRRSTDIR/LSPV.DASD.$RESTORE_DATE | egrep " None "` ]]; then
           waiter2
           mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
           if (( $? == 0 )); then
            other_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            if [[ -n $other_size && -n `echo "$other_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
             print "$i:$other_size:hdisk:EMC">>$DRRSTDIR/EMC_OTHER.$RESTORE_DATE
             print "$i:$other_size:hdisk:EMC">>$logfile
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
           else
            print "$i : Possible time finder drive!  Removing from index file." | tee -a $logfile
            rmdev -dl $i 2>/dev/null 1>>$logfile
           fi
          else
           waiter2
           other_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
           if [[ -n $other_size && -n `echo "$other_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
            print "$i:$other_size:hdisk:EMC">> $DRRSTDIR/EMC_OTHER.$RESTORE_DATE
            print "$i:$other_size:hdisk:EMC">> $logfile
           fi 
          fi
         done
         print "\n\nIndexing DASD_FOUND file!\n"
         rm -f $DRRSTDIR/LSPV.DASD.$RESTORE_DATE
         break

         else
          print "\n\nIndexing DASD_FOUND file!\n"
          break
         fi ;;

      2) if [[ -f $DRRSTDIR/EMC_OTHER.$RESTORE_DATE ]]; then
          emc_count=`wc -l $DRRSTDIR/EMC_OTHER.$RESTORE_DATE | awk '{print $1}'`
         else 
          emc_count=0
         fi 

         if (( $emc_count != `echo "$nonpemc"|wc -l|awk '{print $1}'` )); then 
         rm -f $DRRSTDIR/EMC_OTHER.$RESTORE_DATE
         lspv > $DRRSTDIR/LSPV.DASD.$RESTORE_DATE 
         print "\nIdentifying unknown DASD device!\n" | tee -a $logfile 
         for i in `echo "$nonpemc"|egrep "Other FC SCSI Disk|Other SCSI Disk"|awk '{print $1}'`
          do
          other_size=""
          if [[ -n `egrep "$i " $DRRSTDIR/LSPV.DASD.$RESTORE_DATE|egrep " None "` ]]; then
           waiter2
           mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
           if (( $? == 0 )); then
            other_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            if [[ -n $other_size && -n `echo "$other_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
            for j in `echo "$nonpemc"|egrep "Other FC SCSI Disk|Other SCSI Disk"|awk '{print $1}'`; do

             print "$j:$other_size:hdisk:EMC">>$DRRSTDIR/EMC_OTHER.$RESTORE_DATE
             print "$j:$other_size:hdisk:EMC">>$logfile
             done
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
            break
           else
            print "$i : Possible time finder drive!  Removing from index file." | tee -a $logfile
            rmdev -dl $i 2>/dev/null 1>>$logfile
           fi
          else
           waiter2
           other_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
           if [[ -n $other_size && -n `echo "$other_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
           for j in `echo "$nonpemc"|egrep "Other FC SCSI Disk|Other SCSI Disk"|awk '{print $1}'`; do
             print "$j:$other_size:hdisk:EMC">>$DRRSTDIR/EMC_OTHER.$RESTORE_DATE
             print "$j:$other_size:hdisk:EMC">>$logfile
           done
           break
           fi 
          fi
         done
         rm -f $DRRSTDIR/LSPV.DASD.$RESTORE_DATE
         print "\n\nIndexing DASD_FOUND file!\n"
         break

         else
          print "\n\nIndexing DASD_FOUND file!\n"
          break
         fi ;;

    i|I) print "\nIgnore unidentified DASD!  Continuing with DR Restore\n"
         break ;;
      *) ;;
     esac
     print "\nEnter 1, 2, or I.  \a\n"
     print ">\c\a"
   done
  fi

  ### CHECK FOR ESS (IBM SHARK) SOFTWARE/HARDWARE
  ess_devices=`echo "$DASD_FOUND"|egrep "IBM 2105|IBM FC 2105" | grep Available`
  ess_vpath=`echo "$DASD_FOUND" | grep "^vpath" | grep Available | awk '{print $1}' | sort -n +.5`
  if [[ -n $ess_devices ]]; then
   print "Found ESS DASD!\n"
   ess_devices=""; ess_vpaths=""; ess_serial=""; lsess_2105="";
   if [[ -f /tmp/ess_device.lunid.tmp ]]; then
    rm -f /tmp/ess_device.lunid.tmp
   fi
   if [[ -f /tmp/vpath_config ]]; then
    rm -f /tmp/vpath_config
   fi
   if [[ -f /tmp/vpath_config.tmp ]]; then
    rm -f /tmp/vpath_config.tmp
   fi

   ### ESS utils MUST BE INSTALLED TO QUERY SHARK DISKS
   if [[ -f `which lsess 2>/dev/null` && -f `which ls2105 2>/dev/null` ]]; then

    #### CHECK FOR lsess.out, if not then run lsess
    if [[ ! -f /var/adm/lsess.out && -n $ess_vpath ]]; then  ### CHECK VPATHS 
     if [[ -f /tmp/lsess.out ]]; then
      rm -f /tmp/lsess.out
     fi
     print "\aAttention!  'lsess' has not been run on this system!"
     lsess  | tee -a /tmp/lsess.out
     if [[ -f /tmp/lsess.out ]]; then
      if [[ -n `awk '/Error:/ {print $0}' /tmp/lsess.out` ]]; then
       print "\n\t\t        - OR - \n"
       print "Continue and run config manager, then lsess? i.e. 'cfgmgr -v' and 'lsess'\n"
       con_tinue
       cfgmgr -v
       lsess > /tmp/lsess.out
      fi
     fi

     if [[ -f /usr/lib/methods/cfallvpath ]]; then
      /usr/lib/methods/cfallvpath 2>/dev/null 1>/dev/null
     fi 
     if [[ -f /usr/sbin/addpaths ]]; then
      /usr/sbin/addpaths 2>/dev/null 1>/dev/null
     fi
    fi

    #### CHECK FOR vpaths and datapath command
    datapath="/usr/sbin/datapath"
    if [[ -n $ess_vpath  && ! -f `which datapath 2>/dev/null` ]]; then
     print "Enter the fully qualified PATH to the 'datapath' command:\n"
     while read input; do
     if [[ -f $input && -n `echo "$input" | egrep datapath` ]]; then
      datapath="$input"
      break 
     fi
     print "\nPlease enter fully qualified PATH or quit!"
     con_tinue
     print "\nEnter path: \c"
     done
    fi

    if [[ -f `which ${datapath} 2>/dev/null` ]]; then
     ess_devices=`${datapath} query device`
     ess_vpaths=`echo "$ess_devices" | awk '/vpath/ {print $5}'`
     ess_serial=`echo "$ess_devices" | awk '{RS=""} /vpath0 / {print $0}' | awk -F":" '/SERIAL/ {print $5}'`
     if [[ -n $ess_serial ]]; then ## FIX FOR DIFF VER OF DPO MICROCODE
      waiter2
      echo "$ess_devices" | awk '{RS=""} /vpath[0-9]* / {print $0}' | awk -F":" '/SERIAL/ {print $5}' >> /tmp/ess_device.lunid.tmp
      DPO=0
     else
      waiter2
      echo "$ess_devices" | awk '{RS=""} /vpath[0-9]* / {print $0}' | awk -F":" '/SERIAL/ {print $2}' >> /tmp/ess_device.lunid.tmp
      DPO=1
     fi

    else
     print "No VPATHS!  Using 'ls2105' to query ESS DASD!\n"
     ### SORT on UNIQUE LUN ID
     ess_2105=`ls2105`
     echo "$ess_2105"|awk '/Connection/ {next} {print $3":"$8":"$5}'|awk '/hdisk/ {print $0}'|sort -u -t":" -k3 > $DRRSTDIR/ESS2105_DASD.$$
    
     ess_config=`cat $DRRSTDIR/ESS2105_DASD.$$`
     for i in $ess_config; do
      waiter2
      ess_disk=`echo "$i" | awk -F":" '{print $1}'` 
      ess_disk_size=`echo "$i" | awk -F":" '{print $2}'`
      (( vpath_size = $ess_disk_size * 1000 ))
      sed -es!"$ess_disk:$ess_disk_size"!"$ess_disk:$vpath_size"!g $DRRSTDIR/ESS2105_DASD.$$ > $DRRSTDIR/ESS2105_DASD1.$$
      mv $DRRSTDIR/ESS2105_DASD1.$$ $DRRSTDIR/ESS2105_DASD.$$
     done
     if [[ -f $DRRSTDIR/ESS2105_DASD.$$ ]]; then
      ess_config=`cat $DRRSTDIR/ESS2105_DASD.$$`
      rm -f $DRRSTDIR/ESS2105_DASD.$$
     else
      ess_config=""
     fi
    fi

    if [[ -f /tmp/ess_device.lunid.tmp ]]; then
     sed -es!" "!!g /tmp/ess_device.lunid.tmp > /tmp/ess_device.lunid
     mv /tmp/ess_device.lunid /tmp/ess_device.lunid.tmp
    fi

    for ess_disk in $ess_vpaths; do
     if (( DPO == 0 )); then
      print "${ess_disk}:\c" >> /tmp/vpath_config
      echo "$ess_devices" | awk '{RS=""} /'$ess_disk' / {print $0}' | awk -F":" '/SERIAL/ {print $5}' >> /tmp/vpath_config
      waiter2
     else
      print "${ess_disk}:\c" >> /tmp/vpath_config
      echo "$ess_devices" | awk '{RS=""} /'$ess_disk' / {print $0}' | awk -F":" '/SERIAL/ {print $2}' >> /tmp/vpath_config
      waiter2
     fi
    done

    if [[ -f /tmp/ess_device.lunid.tmp ]]; then
     if [[ -f /var/adm/lsess.out ]]; then
      awk '/hdisk/ {print $0}' /var/adm/lsess.out |awk '{print $1":"$3":"$6}' | awk -F":" '{print $2}' | sort -u > /tmp/lsess_device.lunid.$$
     fi
     diff /tmp/ess_device.lunid.tmp /tmp/lsess_device.lunid.$$ 2>/dev/null 1>/dev/null
     if (( $? != 0 )); then 
      ### USE ls2105 to query SHARK
      print "\n\nThe ESS map file /var/adm/lsess.out is not up-to-date!"
      print "Using 'ls2105' to query ESS DASD!  Please wait!\n"
      ess_2105=`ls2105`
     else
      lsess_2105=`cat /tmp/lsess_device.lunid.$$`
      ess_2105=`awk '{print $1":"$6":"$3}' /var/adm/lsess.out`
     fi
 
     if [[ -n $ess_vpath ]]; then
      if [[ -n $lsess_2105 ]]; then
       ess_config=`echo "$ess_2105"| egrep "hdisk"` 
      else
       ess_config=`echo "$ess_2105"|awk '/Connection/ {next} {print $3":"$8":"$5}'|awk '/hdisk/ {print $0}'`
      fi

      if [[ -f /tmp/ess.out ]]; then
       rm /tmp/ess.out
      fi
      ess_device_vpath=`sort -u /tmp/ess_device.lunid.tmp` 
      for i in `cat /tmp/ess_device.lunid.tmp`; do
       waiter2 
       echo "$ess_config" | awk -F":" '/'${i}'/ {print $1":"$3":"$2*1000}' >> /tmp/ess.out
      done
      awk -F":" '{print $2":"$3}' /tmp/ess.out | sort -t":" -k1.1 -u >> /tmp/vpath_config
      sed -es!" "!!g /tmp/vpath_config >> /tmp/vpath_config.tmp
      rm -f /tmp/vpath_config
      ess_vpath_disks=`awk -F":" '{i=1; {printf("%s ", $i) } }' /tmp/ess.out`
 
      for ess_disk in $ess_vpath; do
       vpath_serial=`awk -F":" '/'$ess_disk':/ {print $2}' /tmp/vpath_config.tmp`
       vpath_size=`awk -F":" '/'$vpath_serial':/ {print $2}' /tmp/vpath_config.tmp`
       print "$ess_disk@$vpath_size" >> /tmp/vpath_config.tmp
      done

     fi
    fi

   else
    ess_size=0
    free_vpath=""
    free_ess_devices=""

    #### CHECK FOR vpaths and datapath command
    datapath="/usr/sbin/datapath"
    if [[ -n $ess_vpath  && ! -f `which datapath 2>/dev/null` ]]; then
     print "Enter the fully qualified PATH to the 'datapath' command:\n"
     while read input; do
     if [[ -f $input && -n `echo "$input" | egrep datapath` ]]; then
      datapath="$input"
      break 
     fi
     print "\nPlease enter fully qualified PATH or quit!\n"
     con_tinue
     print "\nEnter path: \c"
     done
    fi

    ### ESS utils MUST BE INSTALLED TO QUERY SHARK DISKS
    print "ESS utils MUST be installed for automatic size identification of ESS"
    print "DASD!  Please ensure that the 'ls2105, lsess, and datapath' commands"
    print "are in your \$PATH!"
    sep_lin2
    print "\n         Please install the appropriate 'essutil.*' code!"
    sep_lin2
    print "\n\t\t            -- OR --         "
    print "\n1. SLOW!  Walk each ESS 'vpath' or 'hdisk' and verify it's size?"
    print "2. FAST!  Walk one ESS 'vpath' or 'hdisk'  and assign size to all"
    print "   remaining disk(s)." 
    print "\nPlease enter 1, 2, or S for stop and install essutils!\n" 
    print ">\c" 
    while read input; do
     case $input in
      1) if [[ -f `which ${datapath} 2>/dev/null` ]]; then 
         if [[ -n $ess_vpath ]]; then
         free_vpath=`lspv | grep vpath | awk '/None/ {print $1":"}'`
         print "\nIdentifying size of vpath DASD!\n" | tee -a $logfile 

         for i in $ess_vpath; do
          ess_size=0
          if [[ -n `echo "$free_vpath" | egrep "${i}:"`  ]]; then
           waiter2
           mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
           if (( $? == 0 )); then
            ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            if [[ -n $ess_size && -n `echo "$ess_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
             print "$i@$ess_size" >> /tmp/vpath_config.tmp
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
            chdev -l $i -a pv=clear 2>/dev/null 1>/dev/null
           else
            print "$i : Possible ERROR on vpath drive!  Removing from index file." | tee -a $logfile
            rmdev -dl $i 2>/dev/null 1>>$logfile
           fi
          else
           waiter2
           ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
           if [[ -n $ess_size && -n `echo "$ess_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
            print "$i@$ess_size" >> /tmp/vpath_config.tmp
           fi 
          fi
         done
         break
         else
          print "\n\nNo Free VPATHED ESS DASD!\n"
          break
         fi

         else
          ess_devices=`echo "$DASD_FOUND"|egrep "IBM 2105|IBM FC 2105" | grep Available | sort -u -n +.5`
          free_ess_devices=`lspv | egrep "hdisk" | awk '/None/ {print $1":"}'`
          ## ESS DASD ONLY
          for i in `echo "$ess_devices" | awk '{print $1}'`; do
           if [[ -n `echo "$free_ess_devices" | egrep "${i}:"`  ]]; then
           ess_size=0
           waiter2
            mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
            if (( $? == 0 )); then
             ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
             lun_id=`lsattr -El $i | egrep "lun_id" | awk '{print $2}'` 
             print "${i}:${ess_size}:${lun_id}" >> $DRRSTDIR/ESS2105_DASD.$$
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
            chdev -l $i -a pv=clear 2>/dev/null 1>/dev/nulls
           else
            waiter2
            ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            lun_id=`lsattr -El $i | egrep "lun_id" | awk '{print $2}'` 
            print "${i}:${ess_size}:${lun_id}" >> $DRRSTDIR/ESS2105_DASD.$$
           fi
          done
          if [[ -f $DRRSTDIR/ESS2105_DASD.$$ ]]; then
           ess_config=`sort -t":" -u -k 3.1 $DRRSTDIR/ESS2105_DASD.$$`
           rm -f $DRRSTDIR/ESS2105_DASD.$$
          else
           ess_config=""
          fi
          break
         fi ;;

      2) if [[ -f `which ${datapath} 2>/dev/null` ]]; then 
         if [[ -n $ess_vpath ]]; then
         free_vpath=`lspv | grep vpath | awk '/None/ {print $1":"}'`
         print "\nIdentifying size of vpath DASD!\n" | tee -a $logfile 

         ess_size=0
         for i in $ess_vpath; do
          if (( $ess_size == 0 )); then
          if [[ -n `echo "$free_vpath" | egrep "${i}:"`  ]]; then
           waiter2
           mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
           if (( $? == 0 )); then
            ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            if [[ -n $ess_size && -n `echo "$ess_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
             print "$i@$ess_size" >> /tmp/vpath_config.tmp
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
            chdev -l $i -a pv=clear 2>/dev/null 1>/dev/null
           else
            print "$i : Possible ERROR on vpath drive!  Removing from index file." | tee -a $logfile
            rmdev -dl $i 2>/dev/null 1>>$logfile
           fi
          else
           waiter2
           ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
           if [[ -n $ess_size && -n `echo "$ess_size"|awk ' /'[0-9]'/ {print $0}'` ]]; then
            print "$i@$ess_size" >> /tmp/vpath_config.tmp
           fi 
          fi
         else
           waiter2
           print "$i@$ess_size" >> /tmp/vpath_config.tmp
         fi
         done
         break

         else
          print "\n\nNo Free VPATHED ESS DASD!\n"
          break
         fi 

         else
          ## ESS DASD ONLY
          ### NO SORT on UNIQUE LUN ID
          print "\nNO UNIQUE LUN ID CHECKING!  BE SURE THERE ARE NO DUAL ATTACHED ESS HDISKS!\n" 
          ess_size=0
          ess_devices=`echo "$DASD_FOUND"|egrep "IBM 2105|IBM FC 2105" | grep Available | sort -u -n +.5`
          free_ess_devices=`lspv | egrep "hdisk" | awk '/None/ {print $1":"}'`
          ## ESS DASD ONLY
          ### NO SORT on UNIQUE LUN ID
          for i in `echo "$ess_devices" | awk '{print $1}'`; do
           if (( $ess_size == 0 )); then
           if [[ -n `echo "$free_ess_devices" | egrep "${i}:"`  ]]; then
           ess_size=0
           waiter2
            mkvg -f -y $i"IDENT" -s'512' '-n' $i 2>/dev/null 1>>$logfile
            if (( $? == 0 )); then
             ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
             lun_id=`lsattr -El $i | egrep "lun_id" | awk '{print $2}'` 
             print "${i}:${ess_size}:${lun_id}" >> $DRRSTDIR/ESS2105_DASD.$$
            fi 
            varyoffvg $i"IDENT"
            exportvg $i"IDENT"
            chdev -l $i -a pv=clear 2>/dev/null 1>/dev/nulls
           else
            waiter2
            ess_size=`lspv $i | egrep "TOTAL PPs:" | awk '{print $4}' | sed -es!"("!""!g` 
            lun_id=`lsattr -El $i | egrep "lun_id" | awk '{print $2}'` 
            print "${i}:${ess_size}:${lun_id}" >> $DRRSTDIR/ESS2105_DASD.$$
           fi

           else
            waiter2
            print "${i}:${ess_size}:${lun_id}" >> $DRRSTDIR/ESS2105_DASD.$$
           fi
          done
          if [[ -f $DRRSTDIR/ESS2105_DASD.$$ ]]; then
           ess_config=`sort -t":" -u -k 1.1 $DRRSTDIR/ESS2105_DASD.$$`
           rm -f $DRRSTDIR/ESS2105_DASD.$$
          else
           ess_config=""
          fi
          break
         fi;;
    s|S) print "\nStopping DR Restore!  Please install essutils!\n"
         exit 1 ;;
      *) ;;
     esac
     print "\nEnter 1, 2, or S.  \a\n"
     print ">\c\a"
    done
  fi
  fi

  dasd_identify 

  #### PRINT AVAILABE DISKS
  max_hdd=$hdd
  hdd=0
  while (( $hdd < $max_hdd )); do
   if (( `echo ${hdd_avail[$hdd]} |awk '{print $0}'|wc -c` > 1 )); then
    if [[ -n `echo "${hdd_avail[$hdd]}" | awk -F":" '{print $2}'` ]]; then
     print "${hdd_avail[$hdd]}:$hdd" >> $DRRSTDIR/DISKS_AVAIL.$$
    fi
   fi
    (( hdd = $hdd + 1 ))
  done

  if [[ -f $DRRSTDIR/DISKS_AVAIL.$$ ]]; then
  sort -t":" -n -k.6 $DRRSTDIR/DISKS_AVAIL.$$>$DRRSTDIR/DASD_FOUND.$RESTORE_DATE
  hdd=0
   for i in `cat $DRRSTDIR/DASD_FOUND.$RESTORE_DATE`; do
    hdd_avail[$hdd]="$i"
    (( hdd = $hdd + 1 ))
   done
  fi
 
 else ### USING EXISTING DASD_FOUND FILE

  print "Using DASD mapping file: $DRRSTDIR/DASD_FOUND.$RESTORE_DATE\n"

  if [[ -f $DRRSTDIR/DASD_FOUND.$RESTORE_DATE ]]; then
  hdd=0
  sort -t":" -n -k.6 $DRRSTDIR/DASD_FOUND.$RESTORE_DATE>$DRRSTDIR/DASD_FOUND.TMP
  mv $DRRSTDIR/DASD_FOUND.TMP $DRRSTDIR/DASD_FOUND.$RESTORE_DATE
   for i in `cat $DRRSTDIR/DASD_FOUND.$RESTORE_DATE`; do
    hdd_avail[$hdd]="$i"
    (( hdd = $hdd + 1 ))
   done
  fi

 fi

 rm -rf $DRRSTDIR/DISKS_AVAIL.$$

 ### Calculate Size of all ESS HDD's
 if [[ $SNAPSHOT = YES ]]; then
 echo "\n------------------------------------" | tee -a $logfile
 pr -3 -t -w42 -l1 - << END | tee -a $logfile
HDD(s)
  :
SIZE
END
 echo "------------------------------------" | tee -a $logfile
 fi

 for i in `cat $DRRSTDIR/DASD_FOUND.$RESTORE_DATE`
 do
  hddn=`echo $i | awk -F":" '{print $1}'`
  dasd=`echo $i | awk -F":" '{print $2}'`
  if [[ -n $dasd ]]; then
  (( tot_dasd = $tot_dasd + $dasd ))
  fi

 if [[ $SNAPSHOT = YES ]]; then
  pr -3 -t -w42 -l1 - << END | tee -a $logfile
$hddn
  :
$dasd
END
 fi

 done 

 if [[ $SNAPSHOT = YES ]]; then
  if [[ -n $vpath_DASD ]]; then
   for i in $vpath_DASD; do
    dasd_name=`echo "$i" | awk -F":" '{print $1}'` 
    dasd=`echo "$i" | awk -F":" '{print $2}'`
    pr -3 -t -w42 -l1 - << END | tee -a $logfile
$dasd_name
  :
$dasd
END
   done
  fi
 fi

if [[ $SNAPSHOT = YES ]]; then
 print "____________________________________" | tee -a $logfile
 pr -3 -t -w42 -l1 - << END | tee -a $logfile
Total Size 
  :
$tot_dasd MB
END
 print "\n" | tee -a $logfile
fi

 #### Look at the $.rebuild file and determine DASD requirements
 total_dasd_needed=0 
 dasd_needed=""
 
 dasd_needed=`awk '/^VG_DISKS/ {print $0}' $RBLD | sed -es!"VG_DISKS:"!" "!g | sed -es!";"!" "!g`

 ### EXCLUDE VOLUME GROUPS GOES HERE 
 if [[ -f /tmp/EXCLUDE ]]; then
  exclude_tmp=""
  if [[ -n `egrep "^VGNAME:" /tmp/EXCLUDE | awk -F":" '{print $2}'` ]]; then
   sep_lin3 | tee -a $logfile
   print "\aUSING EXCLUDE FILE!  '/tmp/EXCLUDE'" | tee -a $logfile
   exclude_vg=`egrep "^VGNAME:" /tmp/EXCLUDE`
   print "Excluding Volume Group(s): \c" | tee -a $logfile
   h=3
   for i in $exclude_vg; do
    exclude_tmp="$exclude_tmp `echo $i | awk -F":" '{print ":"$2":"}'` "
    print "`echo $i | awk -F":" '{print $2}'` \c" | tee -a $logfile
    (( h = $h + 1 ))
    if (( $h == 7 )); then
     h=0
     print ""
    fi
   done
   print ""
   sep_lin3 | tee -a $logfile
  fi
 fi

 for i in $dasd_needed; do
  disksize=0
  if [[ ! -n $exclude_vg ]]; then

   disks=`echo "$i"|awk -F"@" '{print $2}'|awk -F'-' '{print $3}'|sed s!","!" "!g`
   for j in $disks; do
    (( disksize = $disksize + `echo $j|awk -F: '{print $2}'` ))
   done
   (( total_dasd_needed = $total_dasd_needed + $disksize ))

  else

   vgname="`echo $i | awk -F"@" '{print ":"$1":"}'` "

   if [[ ! -n  `echo "$exclude_tmp" | egrep "$vgname"` ]]; then
   disks=`echo "$i"|awk -F"@" '{print $2}'|awk -F'-' '{print $3}'|sed s!","!" "!g`
   for j in $disks; do
    (( disksize = $disksize + `echo $j|awk -F: '{print $2}'` ))
   done
   (( total_dasd_needed = $total_dasd_needed + $disksize ))
   fi

  fi
 done
 
 gb_need=`echo "scale=2;  $total_dasd_needed / 1000" | bc` 
 tb_need=`echo "scale=2;  $gb_need / 1000" | bc` 
 printf "\n%-18.17s%1s%14.13s" "TOTAL DASD NEEDED" : "$total_dasd_needed MB " | tee -a $logfile
 if (( $gb_need > 0 )); then
  printf "%2s%14.13s" : "$gb_need GB " | tee -a $logfile
  if (( $tb_need > 0 )); then
   printf "%2s%10.9s" : "$tb_need TB" | tee -a $logfile
  fi
  print "" | tee -a $logfile
 else
  print "" | tee -a $logfile
 fi

 gb_tot_dasd=`echo "scale=2;  $tot_dasd / 1000" | bc` 
 tb_tot_dasd=`echo "scale=2;  $gb_tot_dasd / 1000" | bc` 
 printf "%-18.17s%1s%14.13s" "TOTAL DASD FOUND" : "$tot_dasd MB " | tee -a $logfile
 if (( $gb_tot_dasd > 0 )); then
  printf "%2s%14.13s" : "$gb_tot_dasd GB " | tee -a $logfile
  if (( $tb_tot_dasd > 0 )); then
   printf "%2s%10.9s" : "$tb_tot_dasd TB" | tee -a $logfile
  fi
  print "\n" | tee -a $logfile
 else
  print "\n" | tee -a $logfile
 fi

 if (($total_dasd_needed >= $tot_dasd)); then
   print "\nNOT ENOUGH DASD TO MEET REBUILD REQUIREMENTS\a\n"
   (( a_dasd = $total_dasd_needed - $tot_dasd ))
   (( gb_a_dasd = $a_dasd / 1000 ))
   (( tb_a_dasd = $gb_a_dasd / 1000 ))

   print "Amount of additional DASD: $a_dasd MB \c"
   if (( $gb_a_dasd > 0 )); then
    print ": $gb_a_dasd GB \c"
    if (( $tb_tot_dasd > 0 )); then
     print ": tb_a_dasd"" TB " | tee -a $logfile
    else
     print "\n"
    fi
   fi

   sep_lin3
   print "WARNING!  Not enough DASD identified to guarantee successful restore!"
   sep_lin3
   print "\nEnter ('S'/'s') to STOP.  ('I'/'i') to IGNORE and continue: \c"
    while read input; do
      case $input in
       I|i) print "\n"
          clear;
          print "\nContinuing DR Restore!\n";
          break;;
       S|s) print "\nPlease add more DASD and re-run DR Restore!\n"
          exit 1;;
       *) ;;
      esac
      printf "Enter 'S' or 'I' \a"
    done

 fi
 print "" >> $logfile

 rm -rf /tmp/lsess_device.lunid.* /tmp/ess_device.lunid.*
}

####################################################################
#### Returns:  $ssa_needed
####################################################################
find_ssa() 
{
 SSA_RAID=""

 if (( $DR_SNAP_VER > 240 )); then

  if [[ -f $DRRSTDIR/SSARAID.rebuild.orig ]]; then
   SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $DRRSTDIR/SSARAID.rebuild |sed -es!"SSA_RAID:"!!g | sort -t":" -k3.1 -u`
  else
   SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $RBLD |sed -es!"SSA_RAID:"!!g | sort -t":" -k3.1 -u`
  fi

 else

  if [[ -f $DRRSTDIR/SSARAID.rebuild.orig ]]; then
   SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $DRRSTDIR/SSARAID.rebuild |sed -es!"SSA_RAID:"!" "!g|sed -es!";:"!" "!g |sed -es!";"!" "!g`
  else
   SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $RBLD|sed -es!"SSA_RAID:"!" "!g|sed -es!";:"!" "!g |sed -es!";"!" "!g`
  fi

 fi

 if [ -n $SSA_RAID ]; then 
  clear
  print_ver
  sep_line >> $logfile
  print "Verifying that SSA_RAID devices are needed for 'REBUILD'.\n"|tee -a $logfile

  if [[ -f $DRRSTDIR/SSA_RAID.INDEX ]]; then
   rm -f $DRRSTDIR/SSA_RAID.INDEX
  fi

  if [[ -f /tmp/EXCLUDE ]]; then
   check_excludes
  fi

  k=0
  allspares=""
  sep_lin3 | tee -a $logfile 
  pr -5 -t -w76 -l1 - << END | tee -a $logfile
RAID Array
Array Type
# of Pdisks  
Pdisk Size
Size
END
  sep_lin3 | tee -a $logfile 

 if (( $DR_SNAP_VER > 240 )); then

  for l in $SSA_RAID; do
   ssar_cards=`echo $l | awk -F":" '{print $1}'`
   array_type=`echo $l | awk -F":" '{print $2}'`
   if [[ $array_type != HOTSPARES ]]; then
    raid_array=`echo $l | awk -F":" '{print $3}'`
    num_pdisks=`echo $l | awk -F":" '{print $4}'`
    siz_pdisks=`echo $l | awk -F":" '{print $5}'`
    hot_spar=`echo $l   | awk -F":" '{print $6}'`
    pg_split=`echo $l   | awk -F":" '{print $7}'`
    fst_writ=`echo $l   | awk -F":" '{print $8}'`
    siz_array=`echo $l  | awk -F":" '{print $9}'`
    an_rebuilt=`echo $l | awk -F":" '{print $10}'`
    gb_size=$(echo $siz_pdisks|sed -es!GB!""!g)
   else
    spare=`echo $l | awk -F":" '
    { for (i = 3; i <= NF; i++ )
     { printf("%s:", $i) }
      printf("\n")
    }'` 
    if [[ -n $spare && "$spare" != ":" ]]; then
     allspares="$allspares$spare"
    fi 
   fi

    ### CHECK FOR EXCLUDES
    if [[ ! -n `echo "$exclude_all" | egrep "$raid_array:"` ]]; then
     if [[ $array_type != HOTSPARES ]]; then
      ssa_raid[$k]="$raid_array:$array_type:$num_pdisks:$siz_pdisks:$siz_array:$hot_spar:$pg_split:$fst_writ:$an_rebuilt"
      ((k = $k + 1))
      pr -5 -t -w76 -l1 - << END | tee -a $logfile
$raid_array
$array_type
    $num_pdisks
$siz_pdisks
$siz_array
END
     fi
    fi
   done
   max_k=$k

 else

 for i in `echo $SSA_RAID`; do
  ssar_cards=`echo $i | awk -F":" '{print $1}'`
  ssar_devices=`echo $i | sed -es!"$ssar_cards:"!" "!g` 
  ssar_raid0=`echo $ssar_devices | sed -es!"raid_0"!" raid_0"!g` 
  ssar_raid1=`echo $ssar_raid0 | sed -es!"raid_1"!" raid_1"!g` 
  ssar_raid5=`echo $ssar_raid1 | sed -es!"raid_5"!" raid_5"!g` 
  ssar_raid10=`echo $ssar_raid5 | sed -es!"raid_10"!" raid_10"!g` 
  ssar_types=`echo $ssar_raid10`

  for j in $ssar_types; do
   array_type=`echo $j | awk -F: '{print $1}'`
   array_setting=`echo $j|sed -es!"$array_type"!" "!g`
   #echo "ARRAY_SETTINGS: $array_setting"

   for l in $(echo "$array_setting"|sed -es!":-hdisk"!" hdisk"!g); do
    #echo "ARRAY: $l"
    raid_array=`echo $l | awk -F":" '{print $1}'`
    num_pdisks=`echo $l | awk -F":" '{print $2}'`
    siz_pdisks=`echo $l | awk -F":" '{print $3}'`
    hot_spar=`echo $l | awk -F":" '{print $4}'`
    pg_split=`echo $l | awk -F":" '{print $5}'`
    fst_writ=`echo $l | awk -F":" '{print $6}'`
    siz_array=`echo $l | awk -F":" '{print $7}'`
    gb_size=$(echo $siz_pdisks|sed -es!GB!""!g)
    an_rebuilt=`echo $l | awk -F":" '{print $8}'`
    if [[ `echo $an_rebuilt` = REBUILT ]]; then
    spare=`echo $l | awk -F":" '
    { for (i = 9; i <= NF; i = i + 1 )
     { printf("%s:", $i) }
      printf("\n")
      }'` 
    else
    spare=`echo $l | awk -F":" '
    { for (i = 8; i <= NF; i = i + 1 )
     { printf("%s:", $i) }
      printf("\n")
      }'` 
    fi

    if [[ -n $spare && "$spare" != ":" ]]; then
     allspares="$allspares$spare"
     spares=`echo $spare | sed -es!"@"!""!g`
    fi 
    ### CHECK FOR EXCLUDES
    if [[ ! -n `echo "$exclude_all" | egrep "$raid_array:"` ]]; then

     ssa_raid[$k]="$raid_array:$array_type:$num_pdisks:$siz_pdisks:$siz_array:$hot_spar:$pg_split:$fst_writ:$an_rebuilt"
     ((k = $k + 1))
   
     pr -5 -t -w76 -l1 - << END | tee -a $logfile
$raid_array
$array_type
    $num_pdisks
$siz_pdisks
$siz_array
END
    fi
    done

  done
  max_k=$k
 done

 fi
 
 else
  print "No SSA RAID devices required!" | tee -a $logfile 
  SSARAID=NONE
 fi

 allspares="`echo $allspares|sed -es!"@"!""!g`"
 if [[ -n $allspares ]]; then
  print "\nHot Spare(s) NEEDED: $allspares"
  sep_lin2
 fi

}

raid_failed_to_build()
{
 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 best_fit()
 {
  #### Find best fit w/ available drives
  nan_size=$1
  total_numb=$2
  total_need=0
  BUILD=FAIL
  pdsk=$maxpdsk
  # print "MAXPDSK=$maxpdsk"
  # print "BEST FIT ROUTINE"
  # print "Size:$candidate_pdsize"
  # print "${avail_pd[$pdsk]}"

  (( total_need = $total_need + 1 ))
 
  while (( $pdsk >= 0 )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
    candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
    candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
 
    if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
    else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
    fi 
 
    if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND" ]]; then
    if [[ $candidate_rebuilt != REBUILT ]]; then
    if (( $nan_size == $candidate_pdsize )); then
 
     if (( $total_need <= $total_numb )); then
      (( total_need = $total_need + 1 ))
      avail_pd[$pdsk]="${avail_pd[$pdsk]}:REBUILT"
      # print "Size:$candidate_pdsize"
      # print "${avail_pd[$pdsk]}"
     else
      # print "BUILD COMPLETE"
      BUILD=COMPLETE
      break
     fi
 
    fi
    fi
    fi
   fi
 
   fi
   (( pdsk = $pdsk - 1 ))
  done 
 }

 best_fit_smaller()
{ 
  #### Find best fit w/ available drives
  nan_size=$1
  total_numb=$2
  total_need=0
  BUILD=FAIL
  # maxpdsk=$pdsk
  # print "BEST FIT SMALLER ROUTINE"
  # print "Size:$candidate_pdsize"
  # print "${avail_pd[$pdsk]}"
 
  while (( $pdsk >= 0 )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
    candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
    candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
 
    if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
    else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
    fi 
 
    if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND" ]]; then
    if [[ $candidate_rebuilt != REBUILT ]]; then
    if (( $nan_size == $candidate_pdsize )); then
 
     if (( $total_need <= $total_numb )); then
      (( total_need = $total_need + 1 ))
      avail_pd[$pdsk]="${avail_pd[$pdsk]}:REBUILT"
      # print "Size:$candidate_pdsize"
      # print "${avail_pd[$pdsk]}"
     else
      # print "BUILD COMPLETE"
      BUILD=COMPLETE
      break
     fi
 
    fi
    fi
    fi
    fi
 
   fi
   (( pdsk = $pdsk - 1 ))
  done 
  # print "total_numb=$total_numb ; total_found=$total_need"  
 }

 best_fit_any()
 {
  trap 'rm -f /tmp/SSA_HDD_LEFT$$; exit' 1 2 15
  #### Find best fit w/ available drives
  nan_size=$1
  tot_array_size=$2
  total_need=0
  BUILD=FAIL
  pdsk=$maxpdsk
  # print "BEST FIT ANY ROUTINE"
  # print "Size:$tot_array_size"
  # print "${avail_pd[$pdsk]}"
 
  ## FIND WHAT'S LEFT OF PDSK's
  while (( $pdsk >= 0 )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
    candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
    candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
    candidate_rebuilt_found=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $8}'`
 
    if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
    else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
    fi 
 
    if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND" ]]; then
     if [[ $candidate_rebuilt_found != REBUILT-FOUND ]]; then
      # print "${avail_pd[$pdsk]}" 
      print "${avail_pd[$pdsk]}" >> /tmp/SSA_HDD_LEFT$$
     fi
    fi

   fi
   fi
   (( pdsk = $pdsk - 1 ))
  done 

  if [[ -f /tmp/SSA_HDD_LEFT$$ ]]; then
   UNIQUE_DASD=`sort -t":" -u -k4.1 /tmp/SSA_HDD_LEFT$$`
   UNIQUE_DASD=`echo "$UNIQUE_DASD"|awk -F":" '{print $4}'|sed -es!"GB"!""!g`
   rm -rf /tmp/SSA_HDD_LEFT$$
  fi
   
  for m in $UNIQUE_DASD; do
  pdsk=$maxpdsk
  (( numb_needed = $tot_array_size / $m )) 
  if (( $numb_needed < 3 )); then
   numb_needed=3
  fi
  if (( $numb_needed < 16 )); then
  (( total_need = $total_need + 1 ))
  while (( $pdsk >= 0 )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
    candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
    candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
 
    if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
    fi 

    if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND"  ]]; then
    if [[ $candidate_rebuilt != REBUILT ]]; then

     if (( $total_need <= $numb_needed && $m == $candidate_pdsize)); then
      (( total_need = $total_need + 1 ))
      avail_pd[$pdsk]="${avail_pd[$pdsk]}:REBUILT"
      # print "Size:$candidate_pdsize"
      # print "${avail_pd[$pdsk]}"
     else
      # print "BUILD COMPLETE for ROUTINE ANY"
      BUILD=COMPLETE
      break 
     fi

    fi
    fi

    fi
   fi
   (( pdsk = $pdsk - 1 ))
  done 

  fi
  done
 }

 best_fit_multiple()
 {
  NEEDSARRAYS=YES
  #### Find best fit w/ available drives
  nan_size=$1
  total_numb=$2
  tot_array_size=$3
  total_need=0
  BUILD=FAIL
  pdsk=$maxpdsk
  # print "BEST FIT MULTIPLE ROUTINE"
  # print "Size:$candidate_pdsize"
  # print "${avail_pd[$pdsk]}"
  (( total_need = $total_need + 1 ))
 
  while (( $pdsk >= 0 )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
    candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
    candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
 
    if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
    else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
    fi 

    if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND" ]]; then
    if [[ $candidate_rebuilt = REBUILT ]]; then
    if (( $nan_size == $candidate_pdsize )); then
 
     if (( $total_need <= $total_numb )); then
      (( total_need = $total_need + 1 ))
      avail_pd[$pdsk]="${avail_pd[$pdsk]}:REBUILT-FOUND"
      #  print "Size:$candidate_pdsize"
      #  print "${avail_pd[$pdsk]}"
     else
      # print "BUILD COMPLETE"
      BUILD=COMPLETE
      break
     fi

    fi
    fi
    fi

   fi
   fi
   (( pdsk = $pdsk - 1 ))
  done 
 
  if [[ $BUILD != COMPLETE ]]; then
   # (( multiple_array = $total_need * $candidate_pdsize ))
   # (( total_need = $tot_array_size / $candidate_pdsize ))
   (( total_need = $tot_array_size / $nan_size ))
   #(( multiple_array = $total_need * $candidate_pdsize ))
   (( multiple_array = $total_need * $nan_size ))
   # print "Total Needed: $multiple_array = $total_need X $nan_size"
   total_found=0
   pdsk=$maxpdsk
   # print "maxpdsk=$pdsk"
   while (( $pdsk >= 0 )); do
    if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
     candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`

    if [[ -n `echo "$candidate_pdsize" | awk '/[0-9]/ {print $0}'` ]]; then
     candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
     candidate_rebuilt=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $7}'`
     candidate_rebuilt_found=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $8}'`
  
     if [[ $candidate_pstate = CAND ]]; then
         candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
     else
         candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
     fi
  
     if [[ $candidate_pstate = "FREE" || $candidate_pstate = "CAND" ]]; then
      if [[ $candidate_rebuilt_found = REBUILT-FOUND ]]; then
       (( total_found = $total_found + 1 ))
      fi
     fi
    fi
    fi
    (( pdsk = $pdsk - 1 ))
   done
  
   if (( $total_found > 3 && $total_found < 16 )); then
    # print "REBUILD ARRAY W/ $total_found X $candidate_pdsize" 
    ### BUILD ARRAY.  MINUS TOTAL SIZE NEEDED BY BUILT ARRAY 
    candidate_pdsize=$nan_size
    # an_dnumb=$total_found
    print "Rebuild w/ $total_found $candidate_pdsize"
    cand_tsize=`echo "scale=1; $candidate_pdsize * $total_found" | bc`
    print "${ssa_raid[$k]} becomes:"

    export ssa_raid[$k]="$an_hdisk:$an_atype:$total_found:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT \n"

    ## REPLACE ENTRY IN /tmp/drinfo/SSA_RAID.rebuild
    ORIG_ARRAY="$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB:""

     NEW_ARRAY="$an_hdisk:$total_found:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT:"

    # print "NEW_ARRAY=$NEW_ARRAY"

    print "${ssa_raid[$k]}"

    ### BUILD ARRAY.  MINUS TOTAL SIZE NEEDED BY BUILT ARRAY 
    (( still_need = $tot_array_size - ($total_found * $candidate_pdsize) ))
    print "Still need ~${still_need}GB SSA RAID DASD"
    pdsk=$maxpdsk

    best_fit_any $candidate_pdsize $still_need

    if [[ $BUILD = COMPLETE ]]; then

     candidate_pdsize=`echo "scale=1; $m / 1000" | bc`
     (( total_size = $numb_needed * $candidate_pdsize )) 

     # print "BUILDING MULTIPLE PART ARRAY"
     # print "hdisk99:$an_atype:$numb_needed:$candidate_pdsize"GB":$total_size"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT"
     (( max_k = $max_k + 1 ))
     # print "ssa_raid[$max_k] becomes: \c"

     export ssa_raid[$max_k]="hdisk99:$an_atype:$numb_needed:$candidate_pdsize"GB":$total_size"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT"

     print "${ssa_raid[$max_k]}"

     COMBINE_ARRAY="$NEW_ARRAY-hdisk99:$numb_needed:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$total_size"GB":REBUILT:"

    cat $RBLD | sed -es!"$ORIG_ARRAY"!"$COMBINE_ARRAY"!g > $RBLD.new
    cp $RBLD.new $RBLD
    BUILD=COMPLETE
    break 
    fi
 
   else
    print "Not enough SSA DASD to build array!"
    break
   fi

  fi 
 }

 query_rebuild()
 {
  sep_line

  case "$1" in
   snapshot) SNAPSHOT="YES"; shift;;
   *) SNAPSHOT="" ;;
  esac

  print "\aExact matching SSA HDD's were not found!" 
  print "Will try to rebuild w/ closest available matches!"
 
  cp $RBLD $DRRSTDIR/SSARAID.rebuild.orig

  k=$max_k

  ## INDEX ON SSA CARD ONLY
  if [[ -f $DRRSTDIR/SSA_RAID.INDEX ]]; then
   pdsk=0
   for ndx in `cat $DRRSTDIR/SSA_RAID.INDEX`; do
    ssaraid_device=`echo "$ndx" | awk -F":" '{print $1":"$2":"$3":"$4":"$5":"$6}'`
    avail_pd[$pdsk]="${ssaraid_device}"
    (( pdsk = $pdsk + 1 ))
   done
   (( maxpdsk = $pdsk - 1 ))
   pdsk=$maxpdsk
  fi

  while (( $k >= 0 )); do
   if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
    an_hdisk="`echo ${ssa_raid[$k]}|awk -F":" '{print $1}'`"
    an_atype="`echo ${ssa_raid[$k]}|awk -F":" '{print $2}'`"
    an_dnumb="`echo ${ssa_raid[$k]}|awk -F":" '{print $3}'`"
    an_dsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $4}'|sed -es!"GB"!""!g`"
    an_tsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $5}'|sed -es!"GB"!""!g`"
    an_spare="`echo ${ssa_raid[$k]}|awk -F":" '{print $6}'"
    an_pgspl="`echo ${ssa_raid[$k]}|awk -F":" '{print $7}'"
    an_fastw="`echo ${ssa_raid[$k]}|awk -F":" '{print $8}'"
    an_built="`echo ${ssa_raid[$k]}|awk -F":" '{print $9}'"
    pdsk=0
    while (( $pdsk >= 0 )); do
     if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
      candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`
      candidate_pdloop=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $5}'`
      candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
      if [[ $candidate_pstate = FREE || $candidate_pstate = CAND ]]
       then ## BEGIN MAKE SURE PDISK IS FREE/CAND
      
       if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
       else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
       fi 
       #### IF RAID TYPE IS RAID1 USED FIRST AVAIL LARGER THAN PSIZE
       if [[ $an_atype = raid_1 ]]; then
        # print "FOUND RAID1"
        if (( $candidate_pdsize > $an_dsize )); then
         best_fit $candidate_pdsize 2
         if [[ $BUILD = "COMPLETE" ]]; then
          print "Rebuild w/ 2 $nan_size"
          candidate_pdsize=$nan_size
          # print "Rebuild w/ 2 $candidate_pdsize"
          cand_tsize=`echo "scale=1; $candidate_pdsize * $an_dnumb" | bc`
          print "${ssa_raid[$k]} becomes:" 
          export ssa_raid[$k]="$an_hdisk:$an_atype:$an_dnumb:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT \n"

          ## REPLACE ENTRY IN /tmp/drinfo/SSA_RAID.rebuild
          sed -es!"$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB""!"$an_hdisk:$tot_numb:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT"!g $RBLD > $RBLD.new
          cp $RBLD.new $RBLD

          print "${ssa_raid[$k]}"
          break 
         else
          print "REBUILD FAILURE!  MUST USE LARGER PDISKS FOR REBUILD!"
          print "ADD MORE SSA HDD's AND RE-RUN SCRIPT!"
          exit 1 
         fi

         cand_tsize=`echo "scale=1; $candidate_pdsize * $an_dnumb" | bc`
         print "${ssa_raid[$k]} becomes:" 
         export ssa_raid[$k]="$an_hdisk:$an_atype:$an_dnumb:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT \n"

         ## REPLACE ENTRY IN /tmp/drinfo/SSA_RAID.rebuild
         sed -es!"$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB""!"$an_hdisk:$tot_numb:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT"!g $RBLD > $RBLD.new
         cp $RBLD.new $RBLD

         print "${ssa_raid[$k]}"
        fi
        break 
       fi

       #### LOOK AT TOTAL SIZE THEN DIV BY PDSIZE
       #### LOOK LARGER FIRST
       #### CHECK FOR BEST FIT
       # print "cand=$candidate_pdsize : aneed=$an_dsize"

       if (( $candidate_pdsize > $an_dsize )); then   
       tot_numb=0
        (( tot_size = $an_dnumb * $an_dsize ))
        (( tot_numb = $tot_size / $candidate_pdsize ))
        if (( $tot_numb <= 2 )); then
         tot_numb=3
        fi
        (( tot_found = $tot_numb * $candidate_pdsize ))
        if (($tot_found > $tot_size)); then

         best_fit $candidate_pdsize $tot_numb
         if [[ $BUILD = "COMPLETE" ]]; then
          print "Rebuild w/ $tot_numb $nan_size"
          candidate_pdsize=$nan_size
          # print "Rebuild w/ $tot_numb $candidate_pdsize"
          cand_tsize=`echo "scale=1; $candidate_pdsize * $tot_numb" | bc`
          print "${ssa_raid[$k]} becomes:" 
          export ssa_raid[$k]="$an_hdisk:$an_atype:$tot_numb:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT \n"
          
          ## REPLACE ENTRY IN /tmp/drinfo/SSA_RAID.rebuild
          sed -es!"$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB""!"$an_hdisk:$tot_numb:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT"!g $RBLD > $RBLD.new
          cp $RBLD.new $RBLD
          print "${ssa_raid[$k]}" 
          break 
          # else
          #  print "REBUILD FAILURE!  MUST USE LARGER PDISKS FOR REBUILD!"
          #  print "ADD MORE SSA HDD's AND RE-RUN SCRIPT!"
          #  exit 1 
         fi

        else
         print "${ssa_raid[$k]} becomes:" 
         (( tot_numb = $tot_numb + 1 ))
         if (( $tot_numb <= 2 )); then
          tot_numb=3
         fi

         best_fit $candidate_pdsize $tot_numb
         if [[ $BUILD = "COMPLETE" ]]; then
          print "Rebuild w/ $tot_numb $nan_size"
          candidate_pdsize=$nan_size
          # print "Rebuild w/ $tot_numb $candidate_pdsize"
          cand_tsize=`echo "scale=1; $candidate_pdsize * $tot_numb" | bc`
          export ssa_raid[$k]="$an_hdisk:$an_atype:$tot_numb:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT"

          ## REPLACE ENTRY IN /tmp/drinfo/SSA_RAID.rebuild
          sed -es!"$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB""!"$an_hdisk:$tot_numb:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT"!g $RBLD > $RBLD.new
          cp $RBLD.new $RBLD
          print "${ssa_raid[$k]}" 
          break 
          # else
          #  print "REBUILD FAILURE!  MUST USE LARGER PDISKS FOR REBUILD!"
          #  print "ADD MORE SSA HDD's AND RE-RUN SCRIPT!"
          #  exit 1 
         fi
        fi

       fi
      fi  ## END MAKE SURE PDISK IS FREE/CAND

     fi 
     (( pdsk = $pdsk - 1 ))
    done 
 
   fi
   (( k = $k - 1 ))
  done
  #### DONE TRYING TO FIND LARGER DISK

  if [[ $BUILD != COMPLETE ]]; then
  #### FIND SMALLER DISKS TO MAKE ARRAY 
  k=$max_k
  # print "MAXPDSK=$maxpdsk"
  while (( $k >= 0 )); do
  MULTIPLERAIDS=NO
   if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
    an_hdisk="`echo ${ssa_raid[$k]}|awk -F":" '{print $1}'`"
    an_atype="`echo ${ssa_raid[$k]}|awk -F":" '{print $2}'`"
    an_dnumb="`echo ${ssa_raid[$k]}|awk -F":" '{print $3}'`"
    an_dsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $4}'|sed -es!"GB"!""!g`"
    an_tsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $5}'|sed -es!"GB"!""!g`"
    an_spare="`echo ${ssa_raid[$k]}|awk -F":" '{print $6}'"
    an_pgspl="`echo ${ssa_raid[$k]}|awk -F":" '{print $7}'"
    an_fastw="`echo ${ssa_raid[$k]}|awk -F":" '{print $8}'"
    an_built="`echo ${ssa_raid[$k]}|awk -F":" '{print $9}'"
    pdsk=$maxpdsk
    while (( 0 <= $pdsk )); do
     if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
      candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`
      candidate_pdloop=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $5}'`
      candidate_pstate=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
      if [[ $candidate_pstate = FREE || $candidate_pstate = CAND ]]
       then ## BEGIN MAKE SURE PDISK IS FREE/CAND
       if [[ $candidate_pstate = CAND ]]; then
        candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
       else
        candidate_pdsize=`echo "scale=1; $candidate_pdsize / 1000" | bc`
       fi 

       #### LOOK AT TOTAL SIZE THEN DIV BY PDSIZE AND * 1.33 - RAID5 MULTIPLER
       #### LOOKING FOR SIZE SMALLER 
       #### CHECK FOR BEST FIT
       if (( $candidate_pdsize < $an_dsize )); then   
       tot_numb=0
        (( tot_size = $an_dnumb * $an_dsize ))
        (( tot_numb = $tot_size / $candidate_pdsize ))
        if (( $tot_numb <= 2 )); then
         tot_numb=3
        fi
        if (( tot_numb > 16 )); then
         tot_numb=16
         MULTIPLERAIDS=YES
        fi 

        (( tot_found = $tot_numb * $candidate_pdsize ))
        if (($tot_found >= $tot_size)); then

         best_fit_smaller $candidate_pdsize $tot_numb
         candidate_pdsize=$nan_size
         # print "FOUND SMALLER PDISKS"
         if [[ $BUILD = "COMPLETE" && MULTIPLERAIDS != YES ]]; then
          # print "Rebuild w/ $tot_numb $nan_size"
          candidate_pdsize=$nan_size
          # print "Rebuild w/ $tot_numb $candidate_pdsize"
          cand_tsize=`echo "scale=1; $candidate_pdsize * $tot_numb" | bc`
          export ssa_raid[$k]="$an_hdisk:$an_atype:$tot_numb:$candidate_pdsize"GB":$cand_tsize"GB":$an_spare:$an_pgspl:$an_fastw:REBUILT"
          sed -es!"$an_hdisk:$an_dnumb:$an_dsize"GB":$an_spare:$an_pgspl:$an_fastw:$an_tsize"GB""!"$an_hdisk:$tot_numb:$candidate_pdsize"GB":$an_spare:$an_pgspl:$an_fastw:$cand_tsize"GB":REBUILT"!g $RBLD > $RBLD.new
          cp $RBLD.new $RBLD
          print "${ssa_raid[$k]}" 
          break 
         else
          best_fit_multiple $candidate_pdsize $tot_numb $tot_size
          if [[ $BUILD = "COMPLETE" ]]; then
           # print "MULTIPLE BUILD COMPLETE"
           break 
          fi
         fi
        fi  

       fi
      fi
     fi 
     (( pdsk = $pdsk - 1 ))
    done 
   fi
   (( k = $k - 1 ))
  done
  fi
  #### DONE FIND SMALLER DISK TO MAKE ARRAY 
 }

 k=$max_k
 max_k=$k

 while (( $k >= 0 )); do
  if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
  FAILURE=YES
  fi
  (( k = $k - 1 ))
 done
 if [[ $FAILURE = YES ]]; then
  print "\n" | tee -a $logfile
  sep_line | tee -a $logfile
  print "\aSSA RAID Array(s) which FAILED to build: \n" | tee -a $logfile
  k=$max_k
  sep_lin3 | tee -a $logfile
  pr -5 -t -w76 -l1 - << END | tee -a $logfile
RAID Array
Array Type
# of Pdisks
Pdisk Size
Size
END
  sep_lin3 | tee -a $logfile

  while (( $k >= 0 )); do
   if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
    an_hdisk="`echo ${ssa_raid[$k]}|awk -F":" '{print $1}'`"
    an_atype="`echo ${ssa_raid[$k]}|awk -F":" '{print $2}'`"
    an_dnumb="`echo ${ssa_raid[$k]}|awk -F":" '{print $3}'`"
    an_dsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $4}'`"
    an_tsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $5}'`"
    pr -5 -t -w76 -l1 - << END | tee -a $logfile
$an_hdisk
$an_atype
    $an_dnumb
$an_dsize
$an_tsize
END
   fi
  (( k = $k - 1 ))
  done
  k=$max_k
  print "\n"
  if [[ $SNAPSHOT = YES ]]; then
  print "Would you like to rebuild SSA_RAID Arrays with available disks?"
  print "Enter Y/N or Ignore [I/i]:  \c"
  while read input; do
    case $input in
     Y|y) print "\n";
        query_rebuild
        break;;
     I|i) print "\nContinuing DR_Restore w/ above SSA_RAID configuration!"
        break;;
     N|n) print "\nPlease install exact SSA HDD's configuration and re-run DR Restore!\n"
        exit 1;;
     *) ;;
    esac
    printf "Enter Y/N  \a"
  done

  else
   #### REBUILD AUTOMATICALLY W/ AVAIL DISKS
   query_rebuild
  fi
 fi

}


 pre_built()
{
 pdsk=0 
 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 def_arrays=""
 #### LOOK FOR PRE-BUILT FIRST
 print "\n####\n" | tee -a $logfile
 print "Please wait!  Checking for pre-built SSA_RAID devices.\n"
 for i in $ssa_cards; do
 ssa_types=`ssaraid -Ya -l $i | awk '{print $1}'`
 #### CHECK TO SEE IF pdisk are SSARAID SPARES
 ssaraid 2>/dev/null -l $i -Io -t disk -a use=spare |\
 foundspares=` awk -F":" '/^#/ {  head_count=split(substr($0,2),headings,":") }
     ! /^#/ {  field_count=split($0,values,":")
     for ( field=1; field <= head_count; ++field )
      {
        fields[headings[field]]=values[field]
       }
     if ( state_list == "" || index(state_list, fields["state"]) != 0 )
       {
          printf "%s':'%s':'%s':'%s':'%s':'%s;",
                       fields["manager"],
                       fields["name"],
                       fields["use"],
                       fields["state"],
                       fields["size"],
                       fields["class"]
          }
        } ' state_list="${array_states[@]}" `
 
      if [[ -n $foundspares ]]; then
       waiter2
       array_spares="$array_spares$foundspares"
      fi

  #### CHECK TO SEE IF pdisks are a SSARAID ARRAY CANDIDATES
  ssaraid 2>/dev/null -l $i -Io -t disk -a use=free |\
  candidate=` awk -F":" '/^#/ {  head_count=split(substr($0,2),headings,":") }
     ! /^#/ {  field_count=split($0,values,":")
     for ( field=1; field <= head_count; ++field )
      {
        fields[headings[field]]=values[field]
       }
     if ( state_list == "" || index(state_list, fields["state"]) != 0 )
       {
          printf "%s':'%s':'%s':'%s':'%s':'%s;",
                       fields["manager"],
                       fields["name"],
                       fields["use"],
                       fields["state"],
                       fields["size"],
                       fields["class"]
          }
        } ' state_list="${array_states[@]}" `
 
      if [[ -n $candidate ]]; then
       waiter2
       array_candidate="$array_candidate$candidate"
      fi
  
  #### CHECK TO SEE IF hdisk:pdisk are associated w/ and existing Volume Groups
  defined_hdisks=`lspv | egrep -v rootvg | egrep -v None | awk '{print $1}'`
 
  for j in $ssa_types; do
  waiter2
  #### Look for predefined SSA Arrays
  ssaraid 2>/dev/null -l $i -Io -t $j |\
  raid_arrays=` awk -F":" '/^#/ {  head_count=split(substr($0,2),headings,":") }
      ! /^#/ {  field_count=split($0,values,":")
      for ( field=1; field <= head_count; ++field )
       {
         fields[headings[field]]=values[field]
        }
      if ( state_list == "" || index(state_list, fields["state"]) != 0 )
        {
           printf "%s':'%s':'%s':'%s':'%s':'%s\n",
                        fields["manager"],
                        fields["name"],
                        fields["use"],
                        fields["state"],
                        fields["size"],
                        fields["class"]
           } 
         } ' state_list="${array_states[@]}" `
    # print "RAID_ARRAYS:$raid_arrays"
    if [[ -n $raid_arrays ]]; then
     if [[ ! -n `echo $raid_arrays | awk -F":" '{print $1}'` ]]; then
      tmp_def_array=""
      tmp_raid_array=""
      ### BUGGY SSARAID LISTING!! ADD RAID MANAGER ENTRY
      for y in $raid_arrays; do
       waiter2
       tmp_raid_array="$i$y"
       tmp_def_array="$tmp_def_array $tmp_raid_array"
      done
       raid_arrays="$tmp_def_array"
       # print "RAID_ARRAYS:$raid_arrays"
     fi
     def_arrays="$def_arrays`echo $raid_arrays`;"
    fi

  done
 done

check_existing_ssaraid

#### Mark pdisk USED if defined in RAID ARRAY
   
 if [[ $SNAPSHOT = YES ]]; then
  if [[ -n $def_arrays || -n $array_spares || -n $array_candidate ]]; then
   print "DEFINED RAID ARRAYS: " | tee -a $logfile
   for array in `echo $def_arrays | sed -es!";"!" "!g`; do
    print  "$array" | tee -a $logfile
   done
   print "RAID SPARES FOUND: " | tee -a $logfile
   for array in `echo $array_spares | sed -es!";"!" "!g`; do
    print  "$array" | tee -a $logfile
   done
   print "RAID CANDIDATES FOUND: " | tee -a $logfile
   for array in `echo $array_candidate | sed -es!";"!" "!g`; do
    print  "$array" | tee -a $logfile
   done
   print "\n" | tee -a $logfile
  fi
 fi

}

check_prebuilts()
{
 used_hdisk=""
 hdisk=""
 
 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 for i in $ssa_cards; do
  #### USED hdisk/pdisk
  if [[ -n $def_arrays ]]; then
  #############################################################################
   for m in `echo $def_arrays|sed -es!";"!" "!g`; do

    hdisk=`echo $m | awk -F":" '{print $2}'`
    used_hdisk="$used_hdisk $hdisk"
   done
   # print "RAID ARRAYS BELONG TO A VOLUME GROUP=$used_hdisk" 
   #### CHECK LATTER W/ PRE_BUILT VG's

   if [[ -n $defined_hdisks ]]; then
    defined_hdisks=`echo $defined_hdisks|sed -es!"$used_hdisk"!""!g`
    # print "defined_hdisks=`echo $defined_hdisks`"
   for m in `echo $defined_hdisks`; do
    used_hdisk="$used_hdisk $m"
   done
   fi
   # print "USED HDISKS: $used_hdisk"
  fi

  #### SSARAID TYPE SUPPORTED
  ssa_types=`ssaraid -Ya -l $i | awk '{print $1}'`
  if [[ $SNAPSHOT = YES ]]; then
   sep_line | tee -a $logfile
   print "SSA Card $i: RAID Types Supported" | tee -a $logfile
   print "$ssa_types\n">> $logfile
   for rt in $ssa_types; do
    print "$rt \c"
   done
   print "\n"
  fi

  #### Look for pre-built Arrays and compare against what is needed!
  if [[ -n $def_arrays ]]; then
  if [[ -n `echo "$def_arrays" | grep $i 2>/dev/null` ]]; then
  print "\n\nMatching pre-built SSA_RAID arrays:\n" | tee -a $logfile
  print "SSA Card:  $i " | tee -a $logfile
  sep_lin3 | tee -a $logfile
  pr -5 -t -w76 -l1 - << END | tee -a $logfile
RAID Array
Array Type
# of Pdisks  
Pdisk Size
Size
END
  sep_lin3 | tee -a $logfile

   for o in `echo $def_arrays | sed -es!";"!" "!g`; do
    ssama=`echo $o | awk -F":" '{print $1}'`
    hdisk=`echo $o | awk -F":" '{print $2}'`
    if [[ "$ssama" = "$i" ]]; then #### SAME RAID MANAGER AS RAID DEVICE
    #if [[ -n `lspv |grep $hdisk|grep None` ]]; then 
    #### RAID DEFINED HDISK DOES NOT BELONG TO A VG
    pb_hdisk=`echo $o | awk -F":" '{print $2}'`
    pb_state=`echo $o | awk -F":" '{print $4}'`
    pb_tsize=`echo $o | awk -F":" '{print $5}'`
    pb_atype=`echo $o | awk -F":" '{print $6}'`
    pb_settings=$(ssaraid -I -l $i -n $pb_hdisk)
    pb_spare=$(print "$pb_settings"|awk '/^spare[ \t]+/ { print $2 }')
    pb_pgspl=$(print "$pb_settings"|awk '/^allow_page_splits[ \t]+/ { print $2 }')
    pb_fastw=$(print "$pb_settings"|awk '/^fastwrite[ \t]+/ { print $2 }')
    # print "PREBUILT=$pb_hdisk:$pb_state:$pb_spare:$pb_pgspl:$pb_fastw"

     k=$max_k
     while (($k >= 0)); do
      if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
       an_atype="`echo ${ssa_raid[$k]}|awk -F":" '{print $2}'`"
       an_dnumb="`echo ${ssa_raid[$k]}|awk -F":" '{print $3}'`"
       an_dsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $4}'`"
       an_tsize="`echo ${ssa_raid[$k]}|awk -F":" '{print $5}'`"
       an_spare="`echo ${ssa_raid[$k]}|awk -F":" '{print $6}'`"
       an_pgspl="`echo ${ssa_raid[$k]}|awk -F":" '{print $7}'`"
       an_fastw="`echo ${ssa_raid[$k]}|awk -F":" '{print $8}'`"
       # print "ARRAY QUERY: $an_atype:$an_dnumb:$an_dsize:$an_tsize:$an_spare:$an_pgspl:$an_fastw"
       if [[ $an_rebuilt = REBUILT && "$an_tsize" = "$pb_tsize" && \
            "$pb_spare" = "$an_spare" && "$pb_pgspl" = "$an_pgspl" && \
            "$pb_fasw" = "$an_fasw" && "$an_atype" = "$pb_atype" ]]; then
 pr -5 -t -w76 -l1 - << END | tee -a $logfile
$pb_hdisk
$pb_atype
    $an_dnumb
$an_dsize
$an_tsize
END
        ssa_raid[$k]=""
        break

       else

       if [[ "$an_atype" = "$pb_atype" && "$an_tsize" = "$pb_tsize" && \
              "$pb_spare" = "$an_spare" && "$pb_pgspl" = "$an_pgspl" && \
              "$pb_fasw" = "$an_fasw" ]]; then

        if [[ "$pb_state" = "good" || "$pb_state" = "rebuilding" ]]; then
        #### REMOVE AVAILABLE PRE-BUILT ARRAYS
        pr -5 -t -w76 -l1 - << END | tee -a $logfile
$pb_hdisk
$pb_atype
    $an_dnumb
$an_dsize
$an_tsize
END
        # print "FOUND ARRAY=$pb_hdisk:$pb_state:$pb_atype:$pb_tsize:$pb_spare"
        # print "Remove ${ssa_raid[$k]}"
        ssa_raid[$k]=""
        break
        fi
       fi
       fi
      fi
      ((k = $k - 1))
      done
    #fi
    fi #### END SAME RAID MANAGER AS RAID DEVICE
     # print "HDISK $hdisk belongs to volume group `lspv |grep $hdisk|awk '{print $3}'`"
   done
  fi
  fi

  #### CHECK FOR NEEDED SSARAID SPARES ON RAID MANAGER
  if [[ -n $allspares ]]; then
  # print "SPARES NEEDED: $allspares\n"
  #### Look at pre-built spares
  Array_Spares_Found=""
   if [[ -n $array_spares ]]; then

   #### Check for the right sizes
    for ndds in `echo $allspares | sed -es!"pdisk"!" pdisk"!g`; do
     # echo "NDDS=$ndds"
     spare_name=`echo $ndds|awk -F":" '{print $1}'`
     spare_size=`echo $ndds|awk -F":" '{print $2}'`
     # print "SPARE_SIZE=$spare_size"
     for y in `echo $array_spares | sed -es!";"!" "!g`; do
        # echo "Y=$y"
	raid_manager=`echo $y|awk -F":" '{print $1}'`
        pd_name=`echo $y|awk -F":" '{print $2}'`
        pdisk_type=`echo $y|awk -F":" '{print $3}'`
        pd_size=`echo $y|awk -F":" '{print $5}'`
       	if [[ $spare_size = $pd_size && $i = $raid_manager && $pdisk_type = "spare" ]];  then
         # print "\nSPARE AT $i:$pd_name:$pdisk_type:$pd_size" | tee -a $logfile
         print "\n\nFOUND Hot Spare@ $i:$pd_name:$pdisk_type:$pd_size" | tee -a $logfile
         # print "REMOVING FROM AVAILABLE LIST $i:$pd_name:$pdisk_type" | tee -a $logfile
         Array_Spares_Found="$Array_Spares_Found $y"
         array_spares=`echo $array_spares | sed -es!"$y;"!" "!g`
         allspares=`echo $allspares | sed -es!"$ndds"!" "!g`
         break
        else
         #### SET PDISKS TO SPARE
         print "SSA SPARE: $pd_name:$pd_size is useless for $i:$spare_name:$spare_size">> $logfile
        fi
     done
    done
   fi 

   if [[ $SNAPSHOT = YES ]]; then
    if [[ -n $allspares ]]; then
     print "\nSPARES STILL NEEDED: $allspares\n" 
     print "AVAILABLE SPARE DISKS: $array_spares"
     print "AVAILABLE CANDIDATE DISKS: $array_candidate"
    fi
   fi
  fi

 done

 k=$max_k
 while (( $k >= 0 )); do
  if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
   NEEDSARRAYS=YES
  fi
  (( k = $k - 1 ))
 done

 if [[ $SNAPSHOT = YES ]]; then
  if [[ $NEEDSARRAYS = YES ]]; then
  k=$max_k
  print "\n"
  sep_line
  print "SSA RAID Arrays which need to be built: \n"
  while (( $k >= 0 )); do
   if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
    print "${ssa_raid[$k]}"
    NEEDSARRAYS=YES
   fi
   (( k = $k - 1 ))
  done
  print "\n"
  fi
 fi

}

query_pdisks()
{
 FORCE=$1
 pdsk=0 
 k=$max_k
 file_pdisk_count=1
 syst_pdisk_count=0
 syst_hdisk_count=0

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE $DRRSTDIR/SSA_RAID.INDEX; exit' 1 2 15
 
 if [[ "$NEEDSARRAYS" = "YES" ]]; then    #### IF YES THEN BUILD
 # print "PDSK=$pdsk"
 print "\n\nPlease wait!  Identifing PDISKS, HDISKS, and SSA_RAID Arrays!\n" 

 ### CHECKING FOR EXISTING SSA_PDISK FILE
 if [[ -f $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE ]]; then
  if [[ $FORCE = YES ]]; then
   syst_pdisk_count=0
   syst_hdisk_count=0
  else
  ### CHECK NUMBERS OF PDISK/HDISKS IF DIFF - REIDENTIFY SSA PDISKS
   file_pdisk_count=`grep pdisk $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE | grep ":hdisk" |wc -l`
   syst_pdisk_count=`lsdev -Cc pdisk  | grep -i SSA | grep Available |wc -l`
   syst_hdisk_count=`lsdev -Cc disk  | grep -i SSA | grep Available  |wc -l`
  fi
 else
  print ""
 fi

 if (( ( `echo "$syst_pdisk_count"` + `echo "$syst_hdisk_count"` ) / 2 != $file_pdisk_count )); then

 for i in $ssa_cards; do                           #### BEGIN LABEL OF PDISKS
  #### get ssadevice:pdisk:hdisk:size:portA/portB:{FREE/USED}
  slot=$(lsdev -Cc adapter|grep $i|awk '{print $3}')
   for pdisk in $(lsdev -Cc pdisk|grep Avail|grep "$slot"|awk '{print $1}')
    do  ### BEGIN LABEL OF PDISKS
    waiter2
    if [ "`ssaconn -l $pdisk -a $i|awk '{print $3,$4}'`" = "- -" ]; then
     #### Look for RAID spares 
      if [[ -n $array_spares ]]; then ###SPARE
       for n in `echo $array_spares|sed -es!";"!" "!g`; do
        #echo "N:$n"
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $4}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:B:SPARE"
         (( pdsk = $pdsk + 1 ))
         break
        fi
        done
      fi

      if [[ -n $Array_Spares_Found ]]; then ###SPARE
       for n in `echo $Array_Spares_Found|sed -es!";"!" "!g`; do
        waiter2
        #echo "N:$n"
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $4}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:B:SPARE"
         (( pdsk = $pdsk + 1 ))
         break
        fi
        done
      fi
 
      if [[ -n $array_candidate ]]; then ###CANDIDATE
       for n in `echo $array_candidate|sed -es!";"!" "!g`; do
        #echo "N:$n"
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $5}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:B:CAND"
         (( pdsk = $pdsk + 1 ))
         break
        fi
       done
      fi
 
      state="FREE"
      hname=$(ssaxlate -l $pdisk 2>/dev/null)
      if [ $? -eq 0 ]; then
       dsize=$(lsattr -El $(ssaxlate -l $pdisk)|grep size_in_mb|awk '{print $2}' 2>/dev/null)
       if [[ -n $dsize ]]; then
       for u in $used_hdisk; do
        if [[ $u = $(echo $hname) ]]; then
         state="USED"
         break
        fi
       done
       avail_pd[$pdsk]="$i:$pdisk:`echo $hname`:$dsize:B:$state"
       (( pdsk = $pdsk + 1 ))
       fi
 
      else
       hname="N/A"
       dsize="N/A"
      fi
 
    else  #### CHECK A SIDE OF LOOP
 
      if [[ -n $array_spares ]]; then ###SPARE
       for n in `echo $array_spares|sed -es!";"!" "!g`; do
        #echo "N:$n"
        waiter2
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $4}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:A:SPARE"
         (( pdsk = $pdsk + 1 ))
        fi
        break
        done
      fi

      if [[ -n $Array_Spares_Found ]]; then ###SPARE
       for n in `echo $Array_Spares_Found|sed -es!";"!" "!g`; do
        waiter2
        #echo "N:$n"
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $4}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:A:SPARE"
         (( pdsk = $pdsk + 1 ))
         break
        fi
        done
      fi
 
      if [[ -n $array_candidate ]]; then ###CANDIDATE
       for n in `echo $array_candidate|sed -es!";"!" "!g`; do
        if [[ $pdisk = `echo $n | awk -F":" '{print $2}'` ]]; then
         dsize=`echo $n | awk -F":" '{print $5}'`
         avail_pd[$pdsk]="$i:$pdisk:N/A:$dsize:A:CAND"
         (( pdsk = $pdsk + 1 ))
        waiter2
        fi
       done
      fi
 
      state="FREE"
      hname=$(ssaxlate -l $pdisk 2>/dev/null)
      if [ $? -eq 0 ]; then
       dsize=$(lsattr -El $(ssaxlate -l $pdisk)|grep size_in_mb|awk '{print $2}' 2>/dev/null)
       if [[ -n $dsize ]]; then
       for u in $used_hdisk; do
        if [[ $u = $(echo $hname) ]]; then
         state="USED"
         break
        fi
       done
       avail_pd[$pdsk]="$i:$pdisk:`echo $hname`:$dsize:A:$state"
       (( pdsk = $pdsk + 1 ))
       fi
      else
       hname="N/A"
       dsize="N/A"
      fi
    fi
   done 
  done #### END LABEL OF PDISKS

  ### SORT PDISK INTO DECENDING ORDER
  (( maxpdsk = $pdsk - 1 ))
  pdsk=0
  while (( $pdsk <= $maxpdsk )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    print "${avail_pd[$pdsk]}" >> $DRRSTDIR/PDISKS_AVAIL$$
   fi
   (( pdsk = $pdsk + 1 ))
  done

  if [[ -f $DRRSTDIR/PDISKS_AVAIL$$ ]]; then
   sort -t":" -u -k2.1 $DRRSTDIR/PDISKS_AVAIL$$ | sort -t":" -u -n -k2.6 > $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE
  fi

 else
  print "Found existing SSA_PDISK map file!"
 fi

  if [[ -f $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE ]]; then
   pdsk=0
   for i in `cat $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE`; do
    avail_pd[$pdsk]="$i"
    print "${avail_pd[$pdsk]}" >> $DRRSTDIR/SSA_RAID.INDEX
    (( pdsk = $pdsk + 1 ))
   done
  fi

  rm -f $DRRSTDIR/PDISKS_AVAIL$$
  print "\n"

  if [[ $DEBUG = YES ]]; then
   print "SSA Disks Found!" | tee -a $logfile
   sep_lin3 | tee -a $logfile
   print "PdiskName:HdiskName/Size/Loop/Type" | tee -a $logfile
   sep_lin3 | tee -a $logfile
   maxpdsk=$pdsk
   pdsk=0
   while (( $pdsk < $maxpdsk )); do
   if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
    print "${avail_pd[$pdsk]} : $pdsk" | tee -a $logfile
   fi
   (( pdsk = $pdsk + 1 ))
   done
   con_tinue
  fi

 fi
}

rebuild_SSA ()
{
 trap 'rm -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE $DRRSTDIR/SSARAID.rebuild.orig; exit' 1 2 15
 maxpdsk=$pdsk
 pdsk=$maxpdsk
 k=$max_k
 jk=$max_k
 # print "PDSK=$pdsk"
 # print "MAXPDSK=$maxpdsk"
 # print "k=$k"
 if [[ "$NEEDSARRAYS" = "YES" ]]; then    #### IF YES THEN BUILD

 mk_hot_spare ()
 {
   LOOP=$1
   if [[ "$an_spar" = "true" && -n $allspares ]]; then
    if (( `echo "$allspares" | wc -c` > 2 )); then
     ssa_hotspare[$k]="$candidate_manage:$an_type:$an_psiz:$an_spar:$LOOP"
    else 
     allspares=""
    fi
   fi
 }
  
 clear
 print "\n"
 sep_line | tee -a $logfile
 print "Rebuilding SSA_RAID Array(s)\n" | tee -a $logfile

 tmp_allspares=$allspares
 for i in $ssa_cards; do                           #### BEGIN ARRAYS PER CARD
 #### ONLY LOOK AT CARDS THAT HAVE HDD'S ASSOCIATED WITH THEM
 grep $i $DRRSTDIR/SSA_PDISKS.$RESTORE_DATE 2>/dev/null 1>/dev/null
 if [ $? = 0 ]; then
  pdsk=$maxpdsk
  k=$max_k
  ssa_types=`ssaraid -Ya -l $i | awk '{print $1}'`
  for j in $ssa_types; do                              #### BEGIN ARRAY TYPES
   jk=$max_k
   # print "SUPPORTED RAID TYPES: $j on $i"
   # print "CARD $i: TYPE: $j LOOP jk=$jk"
   # print "`echo ${ssa_raid[$jk]}|awk '{print $0}'|wc -c`"
   while (($jk >= 0)); do                     #### BEGIN CHECK FOR NEEDED ARRAY
   if (( `echo ${ssa_raid[$jk]}|awk '{print $0}'|wc -c` > 1 )); then
    #### BEGIN CHECK FOR EMPTY ARRAY
    # print "JK LOOP FOR ${ssa_raid[$jk]}"
    # print "\n"
    an_atype="`echo ${ssa_raid[$jk]}|awk -F":" '{print $2}'`"
    if [[ "$j" = "$an_atype" ]]; then                #### BEGIN ARRAY TYPE MATCH
    # print "ARRAY TYPE SUPPORTED: $an_atype"
    ########################MAIN REBUILD LOOP###################################
    #### Identify arrays requiring spares
    #### CALL BUILD ROUTINES 
    #### CHECK FOR NEEDED SSARAID RAID ARRAYS
    #### BEGIN BUILDING ARRAYS
    #### PRINT NEEDED SSARAID ARRAY
    # print "max_k = $k "
    # print "k=$k"
    # print "Array needed: ${ssa_raid[$jk]}"
    array_spares=""
    while (($k >= 0)); do  #### BEGIN BUILD ARRAY LOOP 
     if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
      ssa_hotspare[$k]=""
      #### BEGIN ARRAY NEEDED TO BE BUILT
      # print "BUILD ARRAY"
      # print "${ssa_raid[$k]}"
      # print "${ssa_raid[$k]}"
      BUILT=NO
      an_hdisk=`echo ${ssa_raid[$k]}| awk -F":" '{print $1}'`
      an_type=`echo ${ssa_raid[$k]}| awk -F":" '{print $2}'`
      an_numb=`echo ${ssa_raid[$k]}| awk -F":" '{print $3}'`
      an_psiz=`echo ${ssa_raid[$k]}| awk -F":" '{print $4}'`
      an_tsiz=`echo ${ssa_raid[$k]}| awk -F":" '{print $5}'`
      an_spar=`echo ${ssa_raid[$k]}| awk -F":" '{print $6}'`
      an_pgsp=`echo ${ssa_raid[$k]}| awk -F":" '{print $7}'`
      an_fast=`echo ${ssa_raid[$k]}| awk -F":" '{print $8}'`
      an_rebuild=`echo ${ssa_raid[$k]}| awk -F":" '{print $9}'`

      #### LOOK FOR CORRECT RAID TYPE
      if [[ $an_type = $j ]]; then
       can_counta=0
       can_countb=0
       build_pdiska=""
       build_pdiskb=""
       avail_numa=4094
       avail_numb=4094
       pdsk=$maxpdsk
       SPARE=NO

       awk '/^'${i}':/ {print $0}' $DRRSTDIR/SSA_RAID.INDEX | awk '/FREE/ || /CAND/ {print $0}' > $DRRSTDIR/SSA_RAID.INDEX.${i}

       check_size=`echo "$an_psiz" | sed -es!GB!!g`
       check_size=`echo "$check_size" | awk -F"." '{print ":"$1}'`

  if [[ -n `egrep "$check_size" $DRRSTDIR/SSA_RAID.INDEX.${i}` ]]; then

   ## INDEX ON SSA CARD ONLY
   if [[ -f $DRRSTDIR/SSA_RAID.INDEX.${i} ]]; then
    pdsk=0
    for ndx in `cat $DRRSTDIR/SSA_RAID.INDEX.${i}`; do
     ssaraid_device=`echo "$ndx" | awk -F":" '{print $1":"$2":"$3":"$4":"$5":"$6}'`
     avail_pd[$pdsk]="${ssaraid_device}"
     (( pdsk = $pdsk + 1 ))
    done
    (( pdsk = $pdsk - 1 ))
    maxpdsk=$pdsk
   fi

   # print "PASS ONE - CANDIDATES"
   if [[ -n `grep CAND $DRRSTDIR/SSA_RAID.INDEX.${i}` ]]; then
    while (( 0 <= $pdsk )); do
     if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then
      #### FIND AVAILABLE PDISKS FOR BUILDING OF ARRAYS AND SPARES 
      #### LOOK FOR ARRAY CANDIDATES FIRST
      if [[ -n $array_candidate ]]; then
       # print "Array Candidates: $array_candidate"
       candidate_manage=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $1}'`
       candidate_pdname=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $2}'`
       candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`
       candidate_pdtype=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $5}'`
       candidate_candid=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
       if (( `echo $allspares |wc -c` <= 2 )); then
        allspares=""
       fi
     
       if [[ "$i" = "$candidate_manage" && "$candidate_pdsize" = "$an_psiz" && "$candidate_candid" = "CAND" ]]
         then
          # print "allspares=$allspares, SPARE=$SPARE"

          #### A LOOP
          if [[ $candidate_pdtype = A ]]; then
           # print "${avail_pd[$pdsk]} A LOOP"
           ((can_counta = $can_counta + 1))
           build_pdiska="$build_pdiska $candidate_pdname"
           avail_numa="$avail_numa:$pdsk"

           if (($an_numb == $can_counta)); then
            for n in `echo $avail_numa | sed -es!":"!" "!g`; do

             if [[ -n ${avail_pd[$n]} ]]; then
              sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
              mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
             fi

             avail_pd[$n]=""
            done
            ssa_raid[$k]=""
            mk_hot_spare A
            if [[ `echo $an_rebuild` = REBUILT ]]; then
             if [[ $CMDSO != YES ]]; then
              print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"|tee -a $logfile
              ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a\ 
               spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/tmp/ssaraid.rebuilt
              diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
              raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`

              cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
              cp $RBLD.new $RBLD
              break 2
             fi
            else
             print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"|tee -a $logfile
             print "\n"
             if [[ $CMDSO != YES ]]; then
              ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/dev/null
             fi
            fi

            BUILT=YES
            ((pdsk = $pdsk - 1))
            break 2

           fi
          fi

          #### B LOOP
          if [[ $candidate_pdtype = B ]]; then
           # print "PDSK=$pdsk"
           # print "${avail_pd[$pdsk]} B LOOP"
           ((can_countb = $can_countb + 1))
           build_pdiskb="$build_pdiskb $candidate_pdname"
           avail_numb="$avail_numb:$pdsk"

           if (($an_numb == $can_countb)); then
            for n in `echo $avail_numb | sed -es!":"!" "!g`; do

             if [[ -n ${avail_pd[$n]} ]]; then
              sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/
SSA_RAID.INDEX.TMP
              mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
             fi

             avail_pd[$n]=""
            done

            ssa_raid[$k]=""
            mk_hot_spare B
             # print "REMOVING ${ssa_raid[$k]}"
             if [[ `echo $an_rebuild` = REBUILT ]]; then
              if [[ $CMDSO != YES ]]; then
               print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"
               ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a\
               spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast \
               2>/dev/null 1>/tmp/ssaraid.rebuilt
               diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
               raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`

               cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
               cp $RBLD.new $RBLD
               break 2
              fi

             else
             print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"
             print "\n"
              if [[ $CMDSO != YES ]]; then
               ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/dev/null
              fi
             fi

              BUILT=YES
              ((pdsk = $pdsk - 1))
              break 2 
           fi
          fi
      fi
     fi
    fi
    ((pdsk = $pdsk - 1))
    #  print "BOTTOM OF LOOP pdsk = $pdsk"
 done   #### END LOOK FOR ARRAY CANDIDATES FIRST
 fi

  if [[ $BUILT = "YES" ]]; then
   # print "BUILT FROM PREDEFINED ARRAYS"
   # print "REMOVING ${ssa_raid[$k]}"
   ssa_raid[$k]=""
   break

  else 

   pdsk=$maxpdsk
   # print "BEGIN LOOKING FOR FREE SYSTEM DISKS:pdsk=$pdsk"
   # print "PASS TWO - FIND PDISKS"
   # print "PDSK=$pdsk"
   # print "COUNTA = $can_counta : COUNTB = $can_countb"
   # print "MAXPDISKS=$pdsk for array ${ssa_raid[$k]}"
   
   SPARE=NO
   while (( 0 <= $pdsk )); do  #### BEGIN REBUILD OF ARRAYS BASED ON QUERY
    if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then  
     #### BEGIN CHECK IF ARRAY IS AVAILABLE
     candidate_manage=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $1}'`
     candidate_pdname=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $2}'`
     candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`
     candidate_pdtype=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $5}'`
     candidate_candid=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
     #### LOOK FOR FREE SYSTEM DISKS NOW
    
     candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
     #print "CAND $candidate_pdname SIZE=$candidate_pdsize"
     pdisk_size=`echo "scale=1; $candidate_pdsize / 1000" | bc 2>/dev/null` 
     ### ON RECHECK/REBUILD pdisk can be N/A because of spares
     # print "pdisk_size = $pdisk_size"
     if [[ ! -n `echo "$pdisk_size" | egrep "[0-9]"` ]]; then
      pdisk_size=0
     fi
     if (( $pdisk_size > 0 )); then
      pdisk_size="$pdisk_size""GB"
     else
      pdisk_size="$candidate_pdsize""GB"
     fi 

     if (( $can_counta >= $can_countb )); then #### BEGIN WORK W/ LOOP A
     #### LOOK ON LOOP A FIRST

      if [[ $i = "$candidate_manage" && "$pdisk_size" = "$an_psiz" && "$candidate_candid" = "FREE" ]]; then

       if [[ "$candidate_pdtype" = "A" ]]; then
         # print "allspares=$allspares"

         SPARE=YES
         # CHANGE HDISK TO FREE PDISK
         # print "${avail_pd[$pdsk]}"
         ((can_counta = $can_counta + 1))
         build_pdiska="$build_pdiska $candidate_pdname"
         avail_numa="$avail_numa:$pdsk"

         if (($an_numb == $can_counta)); then
          # print "build_pdiska=$build_pdiska"
          for y in $build_pdiska; do
           print "ssaraid -l $candidate_manage -H -n $y -a use=free -u" | tee -a $logfile
           if [[ $CMDSO != YES ]]; then
           ssaraid -l $candidate_manage -H -n $y -a use=free -u 2>/dev/null 1>/dev/null
           fi
          done

          for n in `echo $avail_numa | sed -es!":"!" "!g`; do
##NEW
          if [[ -n ${avail_pd[$n]} ]]; then
           sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
           mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi
          ##NEW
          avail_pd[$n]=""
          done
          BUILT=YES
          ((pdsk = $pdsk - 1))
          # print "REMOVING ${ssa_raid[$k]}"
          ssa_raid[$k]=""
          mk_hot_spare A
          print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast" | tee -a $logfile
          print "\n"

          if [[ `echo $an_rebuild` = REBUILT ]]; then
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/tmp/ssaraid.rebuilt
            diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
            raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`

            cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
            cp $RBLD.new $RBLD
            break 2
           fi
          else
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast 2>/dev/null 1>/dev/null
           fi
           break 2
          fi
         fi

       else

        #### LOOK ON LOOP B 
       
       if [[ "$candidate_pdtype" = "B" ]]; then ### BEGIN B LOOP TEST
        # print "allspares=$allspares"
        # print "LOOP B"
        # print "${avail_pd[$pdsk]}"
        SPARE=YES
        ((can_countb = $can_countb + 1))
        build_pdiskb="$build_pdiskb $candidate_pdname"
        avail_numb="$avail_numb:$pdsk"
        if (($an_numb == $can_countb)); then
         for y in $build_pdiskb; do
          print "ssaraid -l $candidate_manage -H -n $y -a use=free -u" | tee -a $logfile
          if [[ $CMDSO != YES ]]; then
           ssaraid -l $candidate_manage -H -n $y -a use=free -u 2>/dev/null 1>/dev/null
          fi
         done

         for n in `echo $avail_numb | sed -es!":"!" "!g`; do
          if [[ -n ${avail_pd[$n]} ]]; then
           sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
           mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi
          avail_pd[$n]=""
         done
         BUILT=YES
         ((pdsk = $pdsk - 1))
         # print "REMOVING ${ssa_raid[$k]}"
         ssa_raid[$k]=""
         mk_hot_spare B
         print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast" | tee -a $logfile
         print "\n"

          if [[ `echo $an_rebuild` = REBUILT ]]; then
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/tmp/ssaraid.rebuilt
            diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
            print "DISKNAME=$diskname"
            raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`
            print "RAIDSIZE=$raidsize"
            cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
            cp $RBLD.new $RBLD
            break 2
           fi
          else
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast 2>/dev/null 1>/dev/null
           fi
           break 2
          fi
        fi
       fi ### END B LOOP TEST
       fi
      fi
      ############ LOOP A
      ############ END   W/ LOOP A

     else  #### ( COUNTA >= COUNT B )

     ############ BEGIN W/ LOOP B

      if [[ "$pdisk_size" = "$an_psiz" && "$candidate_candid" = "FREE" ]]; then
       if [[ "$candidate_pdtype" = "B" ]]; then
        # print "allspares=$allspares"
        # print "Loop B: $pdsk"
        SPARE=YES
        ((can_countb = $can_countb + 1))
        build_pdiskb="$build_pdiskb $candidate_pdname"
        avail_numb="$avail_numb:$pdsk"
        if (($an_numb == $can_countb)); then
         for y in $build_pdiskb; do
          print "ssaraid -l $candidate_manage -H -n $y -a use=free -u"|tee -a $logfile 
          if [[ $CMDSO != YES ]]; then
           ssaraid -l $candidate_manage -H -n $y -a use=free -u 2>/dev/null 1>/dev/null
          fi 
         done

         for n in `echo $avail_numb | sed -es!":"!" "!g`; do
##NEW
          if [[ -n ${avail_pd[$n]} ]]; then
           sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
           mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi
          avail_pd[$n]=""
         done
         # print "build_pdiskb=`echo $build_pdiskb`"
         BUILT=YES
         ((pdsk = $pdsk - 1))
         # print "REMOVING ${ssa_raid[$k]}"
         ssa_raid[$k]=""
         mk_hot_spare B
         print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"|tee -a $logfile
         print "\n"
          if [[ `echo $an_rebuild` = REBUILT ]]; then
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/tmp/ssaraid.rebuilt
            diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
            raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`
            cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
            cp $RBLD.new $RBLD
            break 2
           fi
          else
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiskb -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/dev/null
           fi
           break 2
        fi
        fi

       else

        #### LOOK ON LOOP A 
        # print "SPARE=$SPARE"
        # print "allspares=$allspares"
        # print "${avail_pd[$pdsk]}"
        ((can_counta = $can_counta + 1))
        build_pdiska="$build_pdiska $candidate_pdname"
        avail_numa="$avail_numa:$pdsk"
        if (($an_numb == $can_counta)); then
        for y in $build_pdiska; do
         print "ssaraid -l $candidate_manage -H -n $y -a use=free -u" | tee -a $logfile
         if [[ $CMDSO != YES ]]; then
         ssaraid -l $candidate_manage -H -n $y -a use=free -u 2>/dev/null 1>/dev/null
         fi
        done

         for n in `echo $avail_numa | sed -es!":"!" "!g`; do
##NEW
          if [[ -n ${avail_pd[$n]} ]]; then
          sed -es!"${avail_pd[$n]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
          mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi
          avail_pd[$n]=""
         done
         BUILT=YES
         ((pdsk = $pdsk - 1))
         # print "REMOVING ${ssa_raid[$k]}"
         ssa_raid[$k]=""
         mk_hot_spare A
         print "ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast"|tee -a $logfile
          print "\n"
          mk_hot_spare A  
          if [[ `echo $an_rebuild` = REBUILT ]]; then
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast  2>/dev/null 1>/tmp/ssaraid.rebuilt
            diskname=`grep Available /tmp/ssaraid.rebuilt | awk '{print $1}'`
            raidsize=`ssaraid -Iz -l $i | grep $diskname | awk '{print $4}'`
            cat $RBLD | sed -es!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$an_tsiz"!"$an_hdisk:$an_numb:$an_psiz:$an_spar:$an_pgsp:$an_fast:$raidsize"!g $RBLD > $RBLD.new
            cp $RBLD.new $RBLD
            break 2
           fi
          else
           if [[ $CMDSO != YES ]]; then
            ssaraid -C -d -l $candidate_manage -t $an_type -s$build_pdiska -a \
spare=$an_spar allow_page_splits=$an_pgsp fastwrite=$an_fast 2>/dev/null 1>/dev/null
           fi
           break 2
          fi
         fi

       fi
      fi
      ############ END W/  LOOP B

     fi #### END WORK W/ LOOP B FIRST
    fi  #### END CHECK IF ARRAY IS AVAILABLE
    ((pdsk = $pdsk - 1))
    #  echo "DECREMENT PDSK:=$pdsk"
   done  #### END REBUILD OF ARRAYS BASED ON QUERY

  fi 
  fi ## SEARCH FOR AN_SIZE
  fi                                     #### LOOK FOR CORRECT CORRECT RAID TYPE
  fi                                 ############## END ARRAY NEEDED TO BE BUILT
  # echo "DECREMENT ARRAY LIST:=$k"
  (( k = $k - 1 ))
  done                          ########################### END BUILD ARRAY LOOP


 ########################END MAIN REBUILD LOOP##################################
   fi                                              ######## END ARRAY TYPE MATCH
  fi                                      ############ END CHECK FOR EMPTY ARRAY
   (( jk = $jk - 1 ))
  done                                         ########## END CHECK NEEDED ARRAY
  done                              ############################ END ARRAY TYPES
 fi
 done                           ############################ END ARRAYS PER CARD

 if [[ -n $tmp_allspares ]]; then
 allspares=`echo $tmp_allspares | sed -es!":p"!" p"!g`
 # --------------------------------------------------------------------------- #
 ### BUILD SSA HOT SPARES LAST!  EXACT TYPE ONLY  (BEGIN)
  pdsk=$maxpdsk
  jk=$max_k
  k=$max_k

  while (($jk >= 0)); do                     #### BEGIN CHECK FOR NEEDED TYPE
   print "${ssa_hotspare[$jk]}" >> /tmp/hotspares
   (( jk = $jk - 1 ))
  done

  if [[ -f /tmp/hotspares ]]; then
   print "\nHot Spare(s) being built: " 
   sort -t":" -u -k3.3 /tmp/hotspares > /tmp/hotspares.1
   mv /tmp/hotspares.1 /tmp/hotspares
   jk=0
   for j in `cat /tmp/hotspares`; do
    ssa_hotspare[$jk]="$j"
    (( jk = $jk + 1 ))
   done
   (( max_jk = $jk - 1 ))
   rm -rf /tmp/hotspares
  fi

 for i in $ssa_cards; do                      
  #### BEGIN HOT SPARE(S) PER CARD or PER LOOP

  # MAKE SURE ALL pdisks for an SSA_ARRAY are on the same card!
  awk '/^'${i}':/ {print $0}' $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.${i}

  ## INDEX ON SSA CARD ONLY
  if [[ -f $DRRSTDIR/SSA_RAID.INDEX.${i} ]]; then
   pdsk=0
   for ndx in `cat $DRRSTDIR/SSA_RAID.INDEX.${i}`; do
    ssaraid_device=`echo "$ndx" | awk -F":" '{print $1":"$2":"$3":"$4":"$5":"$6}'`
    avail_pd[$pdsk]="${ssaraid_device}"
    (( pdsk = $pdsk + 1 ))
   done
   (( maxpdsk = $pdsk - 1 ))
  fi

  ssa_types=`ssaraid -Ya -l $i | awk '{print $1}'`
  for j in $ssa_types; do                              #### BEGIN ARRAY TYPES
   # print "SUPPORTED RAID TYPES: $j on $i"
   jk=$max_jk
   pdsk=$maxpdsk

   while (($jk >= 0)); do                     #### BEGIN CHECK FOR NEEDED TYPE
   if (( `echo "${ssa_hotspare[$jk]}"|awk '{print $0}'|wc -c` > 1 )); then
    an_atype="`echo ${ssa_hotspare[$jk]}|awk -F":" '{print $2}'`"
    an_spar=`echo ${ssa_hotspare[$jk]}  |awk -F":" '{print $4}'`
    an_loop=`echo ${ssa_hotspare[$jk]}  |awk -F":" '{print $5}'`
    if [[ "$j" = "$an_atype" && "$an_spar" = "true" ]]; then
     #### BEGIN ARRAY TYPE MATCH
     # print "Array TYPE: $an_atype Found!"
     an_psiz=`echo ${ssa_hotspare[$jk]} | awk -F":" '{print $3}'`
     # print "HOT SPARE= ${ssa_hotspare[$jk]}" 
     # print "an_psiz=$an_psiz"
     # print "an_anspar=$an_spar"
     # print "allspares=$allspares"
     # print "SPARE=$s"
     ### BEGIN HOT SPARE CREATE
     ### AT LEAST ONE HOT SPARE PER LOOP (IF NEEDED)
     pdsk=$maxpdsk
     while (( 0 <= $pdsk )); do
     if (( `echo ${avail_pd[$pdsk]}|awk '{print $0}'|wc -c` > 1 )); then

     #### BEGIN CHECK IF ARRAY NEEDS SPARE
     candidate_manage=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $1}'`
     candidate_pdname=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $2}'`
     candidate_pdsize=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $4}'`
     candidate_pdtype=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $5}'`
     candidate_candid=`echo ${avail_pd[$pdsk]}|awk -F":" '{print $6}'`
     #### LOOK FOR FREE SYSTEM DISKS NOW
    
     candidate_pdsize=`echo $candidate_pdsize|sed -es!"GB"!""!g`
     pdisk_size=`echo "scale=1; $candidate_pdsize / 1000" | bc` 
     if [[ ! -n `echo "$pdisk_size" | egrep "[0-9]" 2>/dev/null` ]]; then
      pdisk_size=0
      # print "PDISK_SIZE=$pdisk_size"
     fi
     if (( $pdisk_size > 0 )); then
      pdisk_size="$pdisk_size""GB"
     else
      pdisk_size="$candidate_pdsize""GB"
     fi 
     # print "MAXPDISKS=$pdsk for array ${ssa_raid[$k]}"

     # ----------------------------------------------------------------------- #
     # print "PASS ONE - CANDIDATES"
     if [[ "$pdisk_size" = "$an_psiz" && "$candidate_candid" = "FREE" ]]; then
      if [[ "$candidate_pdtype" = "$an_loop" ]]; then
       # print "FOUND $an_loop LOOP"
       print "ssaraid -l $candidate_manage -H -n $candidate_pdname -a use=spare -u"|tee -a $logfile 

          if [[ -n ${avail_pd[$pdsk]} ]]; then
           sed -es!"${avail_pd[$pdsk]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
           mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi

        avail_pd[$pdsk]=""
        ssa_hotspare[$jk]=""

        if [[ $CMDSO != YES ]]; then
         ssaraid -l $candidate_manage -H -n $candidate_pdname -a use=spare -u 2>/dev/null 1>/dev/null
         if [ $? -eq 0 ]; then 
          if [[ -n ${avail_pd[$pdsk]} ]]; then
           sed -es!"${avail_pd[$pdsk]}"!!g $DRRSTDIR/SSA_RAID.INDEX > $DRRSTDIR/SSA_RAID.INDEX.TMP
           mv -f $DRRSTDIR/SSA_RAID.INDEX.TMP $DRRSTDIR/SSA_RAID.INDEX
          fi
          avail_pd[$pdsk]=""
          ssa_hotspare[$jk]=""
          SPARE=YES
          break 
         fi
        fi
        SPARE=YES

      fi
     fi
     # ----------------------------------------------------------------------- #
     
     fi
     (( pdsk = $pdsk - 1 ))
     done                  ### END AT LEAST ONE HOT SPARE PER LOOP (IF NEEDED)

    fi				### END HOT SPARE CREATE

   fi 
   (( jk = $jk - 1 ))
   done                                        ### END CHECK FOR NEEDED TYPE
  done 						#### END ARRAY TYPES
 done 						   #### END ARRAYS PER CARD
 allspares=""
 ### BUILD SSA HOT SPARES LAST!  EXACT TYPE ONLY  (END)
fi

fi                           ################################ IF YES THEN BUILD

## IF REBUILD != ORIG REBUILD THEN COPY
if [[ -f $DRRSTDIR/SSARAID.rebuild.orig ]]; then
 if [[ ! -f $DRRSTDIR/SSARAID.rebuild ]]; then
  cp -r $RBLD $DRRSTDIR/SSARAID.rebuild
 fi
fi

}

####################################################################
#### Checks spares and arrays
####################################################################
check_all()
{
 trap 'rm -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE; exit' 1 2 15

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac
 
 if [[ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]]; then
  rm -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE
 fi

 if [[ $SNAPSHOT = YES ]]; then
 clear
 print "\n"
 sep_line | tee -a $logfile
 print "Status of built SSA_RAID Arrays:\n" | tee -a $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE

 sep_lin3 | tee -a $logfile
 pr -5 -t -w76 -l1 - << END | tee -a $logfile
RAID Device
 Serial Number
  Type  

Size
END
 sep_lin3 | tee -a $logfile
 for i in $ssa_cards; do
  print "SSA CARD: $i"
  ssaraid -Iz -l $i|egrep "RAID|spare" 2>/dev/null|tee -a $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE
  done

  else

   sep_line >> $logfile
   for i in $ssa_cards; do
    ssaraid -Iz -l $i|egrep "RAID|spare" 2>/dev/null >> $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE
   done

  fi
}

################################################################################
# MAIN SSARAID REBUILD ROUTINE - CALLS MULTIPLE SUB ROUTINES
# - find_ssa, pre_built, check_prebuilts, query_pdisks, rebuild_SSA, check_all
# IF Failures on rebuild
# - raid_failed_to_build, rebuild_SSA, check_all 
################################################################################
main_ssaraid_rebuild()
{

####### #BEGIN MAIN SSARAID ROUTINE ########
case "$1" in
 snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
esac

trap 'rm -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE $DRRSTDIR/PDISKS_AVAIL*; exit' 1 2 15

check_excludes()
{
 ### IF EXCLUDE A VOLUME GROUP, CHECK DISKS W/I VG AND MAKE SURE THEY ARE NOT 
 ### SSA RAID DISKS
 if [[ -f /tmp/EXCLUDE ]]; then
  exclude_tmp=""
  exclude_vg=`egrep "^VGNAME:" /tmp/EXCLUDE`
  if [[ -n `echo $exclude_vg" | awk -F":" '{print $2}'` ]]; then

   VGN=`awk '/^VG_DISKS/ {print $0}' $RBLD | sed -es!"VG_DISKS:"!" "!g | sed -es!";"!" "!g`

   sep_lin3 | tee -a $logfile
   print "\aUSING EXCLUDE FILE!  '/tmp/EXCLUDE'" | tee -a $logfile
   print "Excluding Disk(s) from Volume Group(s): \c" | tee -a $logfile

   h=3
   for i in $exclude_vg; do
    ### FIND DISKS
    exclude_tmp="$exclude_tmp `echo $i | awk -F":" '{print $2":"}'`"
    print "`echo $i | awk -F":" '{print $2}'` \c" | tee -a $logfile
    (( h = $h + 1 ))
    if (( $h == 7 )); then
     h=0
     print ""
    fi
   done

   print "" | tee -a $logfile
   exclude_vg="$exclude_tmp"

   exclude_dasd_tmp=""
   for i in `echo $VGN`; do
    vg_name="`echo $i | awk -F"@" '{print $1":"}'`"
    if [[ -n `echo $exclude_vg | egrep "${vg_name}"` ]]; then
     exclude_dasd=`echo "$i"|awk -F"@" '{print $2}'|awk -F"-" '{print $3}'`
     for j in `echo "$exclude_dasd"|sed -es!","!" "!g`; do
      exclude_dasd="`echo "$j" | awk -F":" '{print $1}'`:"
      exclude_dasd_tmp="$exclude_dasd_tmp $exclude_dasd"
     done
    fi
   done

   exclude_dasd=$exclude_dasd_tmp

   ### CHECK FOR EXCLUDED SSARAID DEVICES 
   exclude_ssa=`egrep "SSARAID:" /tmp/EXCLUDE`
   if [[ -n `egrep "^SSARAID:" /tmp/EXCLUDE | awk -F":" '{print $2}'` ]]; then
    print "Excluding SSA RAID Disk(s):  \c" | tee -a $logfile
    exclude_ssa_tmp=""
    for i in `echo "$exclude_ssa"|awk -F":" '{print $2}'`; do
     print "$i \c" | tee -a $logfile
     exclude_ssa_tmp="$exclude_ssa_tmp $i:" 
    done
    print "" | tee -a $logfile
    exclude_ssa="$exclude_ssa_tmp"
   fi

   exclude_all="$exclude_dasd $exclude_ssa"
   # print "\nEXCLUDE_all=$exclude_all\n"
   sep_lin3 | tee -a $logfile
   print "\n" | tee -a $logfile
  fi
 fi
 ### EXCLUDE VOLUME GROUPS GOES HERE
}

check_existing_ssaraid()
{
if (( $DR_SNAP_VER > 240 )); then
 ## CHECK TOTAL SSARAID SIZE BUILT AGAINST NEEDED SIZE
 if [[ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE && -n $SSA_RAID ]]; then
  total_needed_ssaraid=0
  total_rebuilt_ssaraid=0
  for i in `echo "$SSA_RAID"|egrep -v HOTSPARES`; do 
   an_tsiz=`echo $i | awk -F":" '{print $9}'`
   an_tsiz=`echo "$an_tsiz" | sed -es!"GB"!!g`
   (( total_needed_ssaraid = $total_needed_ssaraid + $an_tsiz ))
  done
  BLT_SSARAID=`awk '/^hdisk/ {print $4}' $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE`
  for i in `echo "$BLT_SSARAID"`; do
   built_tsiz=`echo "$i" | sed -es!"GB"!!g`
   (( total_rebuilt_ssaraid = $total_rebuilt_ssaraid + $built_tsiz ))
  done
 
  if (( $total_rebuilt_ssaraid >= $total_needed_ssaraid )); then
   SSA_RAID=""
   def_arrays=""
  fi
 fi
fi
}

if [[ -f $DRRSTDIR/SSARAID.rebuild.orig ]]; then

 ### CHECK NEW DR_VERSION
 if (( $DR_SNAP_VER > 240 )); then
  SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $DRRSTDIR/SSARAID.rebuild.orig |sed -es!"SSA_RAID:"!!g | sort -t":" -k3.1 -u`
 else
  SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $DRRSTDIR/SSARAID.rebuild.orig|sed -es!"SSA_RAID:"!" "!g|sed -es!";:"!" "!g |sed -es!";"!" "!g`
 fi

else

 if (( $DR_SNAP_VER > 240 )); then
  SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $RBLD |sed -es!"SSA_RAID:"!!g | sort -t":" -k3.1 -u`
 else
  SSA_RAID=`awk '/^SSA_RAID/ {print $0}' $RBLD |sed -es!"SSA_RAID:"!" "!g|sed -es!";:"!" "!g |sed -es!";"!" "!g`
 fi


 if [[ -n `echo "$SSA_RAID" | grep -i raid 2>/dev/null` ]]; then

  if [[ -n `lsdev -Cc adapter | grep -i ssa` ]]; then
   ssa_cards=`ssaraid -M 2>/dev/null | sort`
   if [[ -n $ssa_cards ]]; then
    check_all
   fi
  fi
 fi
fi

check_existing_ssaraid

if [[ -n $SSA_RAID ]]; then

 which ssaraid 2>/dev/null 1>>$logfile
 if (($? != 0)); then
  print "WARNING!"
  print "ssaraid must be in the PATH for the rebuild to work!"|tee -a $logfile
  print "Build the SSA RAID Devices Manually and rerun 'dr_restore.sh'"
  sleep 4
 fi

 #### make sure you can map hdisks to pdisks
 which ssaxlate 2>/dev/null 1>>$logfile
 if (($? != 0)); then
  print "ssaxlate must be in the PATH for the rebuild to work!"|tee -a $logfile
  print "Build the SSA RAID Devices Manually and rerun 'dr_restore.sh'"
  exit 1
 fi

 #### make sure you can map hdisks to pdisks
 which ssaconn 2>/dev/null 1>>$logfile
 if (($? != 0)); then
  print "ssaconn must be in the PATH for the rebuild to work!"|tee -a $logfile
  print "Build the SSA RAID Devices Manually and rerun 'dr_restore.sh'"
  exit 1
 fi

 #### identify ssaraid cards
 ssa_cards=`ssaraid -M | sort`

 find_ssa 
 if [[ -n $ssa_cards ]]; then

  if [[ $SNAPSHOT = YES ]]; then
   SNAPSHOT=NO
   pre_built 
   SNAPSHOT=YES
  else
   SNAPSHOT=NO
   pre_built 
  fi

  if [[ $SNAPSHOT = YES ]]; then
   SNAPSHOT=NO
   check_prebuilts
   SNAPSHOT=YES
  else
   SNAPSHOT=NO
   check_prebuilts
  fi

  if [[ $SNAPSHOT = YES ]]; then
   query_pdisks snapshot
  else
   query_pdisks 
  fi

  if [[ $SNAPSHOT = YES ]]; then
   rebuild_SSA snapshot 
  else
   rebuild_SSA 
  fi

  if [[ $SNAPSHOT = YES ]]; then
   check_all snapshot
  else
   check_all 
  fi

  if [[ $SNAPSHOT = YES ]]; then
   raid_failed_to_build snapshot
  else
   raid_failed_to_build 
  fi
  k=$max_k
  while (( $k >= 0 )); do
   if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
    BUILD_FAILURE=YES
    # print "ARRAY: ${ssa_raid[$k]}"
   fi
   (( k = $k - 1 ))
  done

  if [[ $BUILD_FAILURE = YES ]]; then
   pre_built

   used_hdisk=""
   for m in `echo $def_arrays|sed -es!";"!" "!g`; do
    hdisk=`echo $m | awk -F":" '{print $2}'`
    used_hdisk="$used_hdisk $hdisk"
   done

   query_pdisks YES

   k=$max_k
   pdsk=$maxpdsk
   allspares=""
   if [[ $SNAPSHOT = YES ]]; then
    rebuild_SSA snapshot
    check_all 
   else 
    rebuild_SSA 
    check_all 
   fi
  fi

  if [[ $CMDSO != YES ]]; then
   k=$max_k
   BUILD_FAILURE=NO
   while (( $k >= 0 )); do
     if (( `echo ${ssa_raid[$k]}|awk '{print $0}'|wc -c` > 1 )); then
     BUILD_FAILURE=YES
     fi
     (( k = $k - 1 ))
    done
   if [[ $BUILD_FAILURE = YES ]]; then
    print "\nNot enough SSA HDD's to rebuild all SSA RAID Devices!\a"
    print ""
    print "Would you like to 'Stop' and add more SSA HDD's or 'Ignore'" 
    print "and continue restore on NON-RAID protected DASD!\n"
    print "Enter ('S'/'s') to STOP.  ('I'/'i') to IGNORE and continue DR Restore: \c"
    while read input; do
      case $input in
       I|i) print "\n"
          print "\nContinuing DR Restore!";
          break;;
       S|s) print "\nPlease add more SSA HDD's and re-run DR Restore!\n"
          exit 1;;
       *) ;;
      esac
      printf "Enter 'S' or 'I' \a"
    done
   fi 
  fi 

 else
  print "\a"
  print "NO SSA RAID CARDS FOUND!\n"
  print "Would you like to continue?"
  print "Enter Y/N \c"
   while read input; do
     case $input in
      Y|y) print "\n"
         print "\nContinuing DR Restore Run!";
         break;;
      N|n) print "\nPlease fix SSA Cards and re-run DR Restore!\n"
         exit 1;;
      *) ;;
     esac
     printf "Enter Y/N  \a"
   done
 fi

 fi
 rm -f $DRRSTDIR/PDISKS_AVAIL1.$$ $DRRSTDIR/SSA_RAID.INDEX $DRRSTDIR/SSA_RAID.INDEX.* 
######## END MAIN SSARAID ROUTINE ########
}

################################################################################
### Re-index DASD_FOUND if SSARAID_DASD.$RESTORE_DATE exists
################################################################################
index_dasd_map()
{
 trap 'rm -f $DRRSTDIR/DISKS_AVAIL.$$ $DRRSTDIR/DASD_FOUND.$RESTORE_DATE $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.TMP $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.SSA; exit' 1 2 15

 hdd=0

 if [[ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]]; then
  if (( `wc -l $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE | awk '{print $1}'` >= 1 ));
  then

   print "\nRe-Indexing DASD_FOUND file!  Please wait!\n"
   awk ' /EMC|ESS|SCSI|SERIAL|SSARAID-SPARE/ {print $0}' $DRRSTDIR/DASD_FOUND.$RESTORE_DATE > $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.TMP
   awk ' !/EMC|ESS|SCSI|SERIAL|SSARAID-SPARE/ {print $0}' $DRRSTDIR/DASD_FOUND.$RESTORE_DATE > $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.SSA

   mv $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.SSA $DRRSTDIR/DASD_FOUND.$RESTORE_DATE
 
   dasd_identify SSARAID
   ### REPRINT DASD FILE THAT JUST CONTAINS SSA/SCSI DISKS
   max_hdd=$hdd
   hdd=0
   while (( $hdd < $max_hdd )); do
    if (( `echo ${hdd_avail[$hdd]} |awk '{print $0}'|wc -c` > 1 )); then
     print "${hdd_avail[$hdd]}" >> $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.SSA
    fi
    (( hdd = $hdd + 1 ))
   done

   mv $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.SSA $DRRSTDIR/DASD_FOUND.$RESTORE_DATE

   sort -t":" -n -k1.6 $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.TMP>>$DRRSTDIR/DASD_FOUND.$RESTORE_DATE  
   rm -rf $DRRSTDIR/DASD_FOUND.$RESTORE_DATE.TMP 
  fi
 fi

}

####################################################################
#### Returns:  $VGN
####################################################################
find_vgn() 
{
 k=0
 VGN=""

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 VGN=`awk '/^VG_DISKS/ {print $0}' $RBLD |sed -es!"VG_DISKS:"!" "!g | sed -es!";"!" "!g`
 # echo "VGN: $VGN"

 if [[ -n $VGN ]]; then 
 clear
 print_ver

 ### EXCLUDE VOLUME GROUPS GOES HERE 
 if [[ -f /tmp/EXCLUDE ]]; then
  exclude_tmp=""
  VGN_TMP=""
  if [[ -n `egrep "VGNAME:" /tmp/EXCLUDE | awk -F":" '{print $2}'` ]]; then
   sep_lin3 | tee -a $logfile
   print "\aUSING EXCLUDE FILE!  '/tmp/EXCLUDE'" | tee -a $logfile
   exclude_vg=`egrep "^VGNAME:" /tmp/EXCLUDE`
   print "Excluding Volume Group(s):  \c" | tee -a $logfile
   h=3
   for i in $exclude_vg; do
    exclude_tmp="$exclude_tmp `echo $i | awk -F":" '{print ":"$2":"}'`"
    print "`echo $i | awk -F":" '{print $2}'` \c" | tee -a $logfile
    (( h = $h + 1 ))
    if (( $h == 7 )); then
     h=0
     print ""
    fi
   done

   export exclude_vg="$exclude_tmp"

   print "" | tee -a $logfile
   sep_lin3 | tee -a $logfile
   print "" | tee -a $logfile
   for i in `echo $VGN`; do
    vg_name="`echo $i | awk -F"@" '{print ":"$1":"}'` "
    if [[ ! -n `echo "$exclude_tmp" | egrep $vg_name` ]]; then
     VGN_TMP="$VGN_TMP $i"
    fi
   done
   VGN="$VGN_TMP"
  fi
 fi
 ### EXCLUDE VOLUME GROUPS GOES HERE

 sep_line >> $logfile
 print "Verifying that Volume Groups are needed for 'REBUILD'.\n"|tee -a $logfile

 if [[ $SNAPSHOT = YES ]]; then
 sep_lin3 | tee -a $logfile
  pr -6 -t -w78 -l1 - << END | tee -a $logfile
VG Name
PP Size
ConCap
Pdisks
Type
Size(GB)
END
 sep_lin3 | tee -a $logfile
 fi

 #### CAPTURE DASD IN *.long_listing
 DASD=`awk '/^hdisk|^vpath|^hdiskpower|^dlmfdrv/ {print $0}' $LLST| awk '/Available/ {print $0}' |sort -u -d -k1`

 #### CAPTURE DASD IN SSARAID
 if (( $DR_SNAP_VER > 240 )); then

  SSA_RAID_DASD=`awk '/^SSA_RAID/ {print $0}' $RBLD |sed -es!"SSA_RAID:"!!g`
  if [[ -n $SSA_RAID_DASD ]]; then
   SSA_RAID_TYPE=""
   for l in $SSA_RAID_DASD; do
    ssar_cards=`echo $l | awk -F":" '{print $1}'`
    array_type=`echo $l | awk -F":" '{print $2}'`
    if [[ $array_type != HOTSPARES ]]; then
     raid_array=`echo $l | awk -F":" '{print $3}'`
     SSA_RAID_TYPE="$raid_array $SSA_RAID_TYPE \c"
    fi
   done
  else
   SSA_RAID_TYPE=""
  fi

 else

 SSA_RAID_DASD=`awk '/^SSA_RAID/ {print $0}' $RBLD |sed -es!"SSA_RAID:"!" "!g|sed -es!";:"!" "!g | sed -es!";"!" "!g`
 if [[ -n $SSA_RAID_DASD ]]; then
 SSA_RAID_TYPE=""
  for i in `echo $SSA_RAID_DASD`; do
   ssar_cards=`echo $i | awk -F":" '{print $1}'`
   ssar_devices=`echo $i | sed -es!"$ssar_cards:"!" "!g`
   ssar_raid0=`echo $ssar_devices | sed -es!"raid_0"!" raid_0"!g`
   ssar_raid1=`echo $ssar_raid0 | sed -es!"raid_1"!" raid_1"!g`
   ssar_raid5=`echo $ssar_raid1 | sed -es!"raid_5"!" raid_5"!g`
   ssar_raid10=`echo $ssar_raid5 | sed -es!"raid_10"!" raid_10"!g`
   ssar_types=`echo $ssar_raid10`
   for j in $ssar_types; do
    array_type=`echo $j | awk -F: '{print $1}'`
    array_setting=`echo $j|sed -es!"$array_type"!" "!g`
    for l in $(echo "$array_setting"|sed -es!":-hdisk"!" hdisk"!g); do
     raid_array=`echo $l | awk -F":" '{print $1}'`
     SSA_RAID_TYPE="$raid_array $SSA_RAID_TYPE \c"
    done
   done
  done
 fi

 fi

 #### CAPTURE DASD IN SSA
 if [[ -n $SSA_RAID_TYPE ]]; then
  for i in `echo $SSA_RAID_TYPE`; do
  EXCLUDES="$EXCLUDES |$i "
  done
  EXCLUDES=`echo $EXCLUDES | sed -es!"^|"!""!g`
 fi

 if [[ -n $EXCLUDES ]]; then
  SSA_DASD=`echo "$DASD" | awk ' /SSA/ {print $0}' | egrep -v "$EXCLUDES"`
 else
  SSA_DASD=`echo "$DASD" | awk ' /SSA/ {print $0}'`
 fi
 # print "SSA_DASD=$SSA_DASD"

 #### CAPTURE DASD IN VPATH ESS
 VPATH_DASD=`echo "$DASD" | awk ' /^vpath/ {print $0}'`
 
 #### CAPTURE DASD IN 2105 ESS
 SHARK_DASD=`echo "$DASD" | awk ' /hdisk/ {print $0}' |awk ' /2105/ {print $0}'`

 #### CAPTURE DASD IN SCSI
 SCSI_DASD=`echo "$DASD"|awk ' !/hdiskpower|Other|dlmfdrv/ {print $0}'|awk ' /SCSI/ {print $0}'`

 #### CAPTURE HDISK IN EMC POWER
 EMC_DASD=`echo "$DASD" | awk ' /^hdiskpower/ {print $0}'`

 if [[ -n $EMC_DASD ]]; then
  EMC_DASD="$EMC_DASD \n `echo "$DASD" | awk ' /hdisk/ {print $0}' |awk ' /EMC/ {print $0}'`"
 else
 #### CAPTURE HDISK IN EMC 
  EMC_DASD=`echo "$DASD" | awk ' /hdisk/ {print $0}' |awk ' /EMC/ {print $0}'`
 fi

 #### CAPTURE HDISK IN HITACHI
 HITACHI_DASD=`echo "$DASD" | awk ' /^dlmfdrv/ {print $0}'`
 if [[ -z $HITACHI_DASD ]]; then
  HITACHI_DASD=`echo "$DASD" | awk ' /Hitachi|HITACHI/ {print $0}'`
 fi

 ### CAPTURE HDISK IN FC_SCSI
 FC_SCSI_DASD=`echo "$DASD" | awk ' /FC SCSI Disk/ {print $0}'`

 #### CAPTURE HDISK IN OLD SSA SERIAL DISK
 SSA_SERIAL=`echo "$DASD" | grep -i "Serial-Link"`

 smallest_size=0 
 for i in `echo $VGN`; do
  vg_tsize=0
  vg_numb=0
  vg_hdsize=""
  vg_type=""
  vg_name=`echo $i | awk -F"@" '{print $1}'`
  vg_ppsiz=`echo $i | awk -F"@" '{print $2}'|awk -F"-" '{print $1}'`
  vg_conca=`echo $i | awk -F"@" '{print $2}'|awk -F"-" '{print $2}'`
  vg_hdisk=`echo $i | awk -F"@" '{print $2}'|awk -F"-" '{print $3}'` 
  TYPE_FOUND=NO

   for j in `echo $vg_hdisk | sed -es!","!" "!g`; do
    (( vg_tsize = $vg_tsize + $(echo $j | awk -F":" '{print $2}') ))
    (( vg_numb = $vg_numb + 1 ))
    vg_hdsize="$vg_hdsize;$j" 
    disk_name=`echo $j|awk -F":" '{print $1}'`
    
     ### LOOK FOR SSARAID 
     if [[ -n $SSA_RAID_TYPE && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$SSA_RAID_TYPE" | grep "$disk_name "` ]]; then
       vg_type="SSARAID"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR SSA 
     if [[ -n $SSA_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$SSA_DASD" | grep "$disk_name "` ]]; then
       vg_type="SSA"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR SCSI 
     if [[ -n $SCSI_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$SCSI_DASD" | grep "$disk_name "` ]]; then
       vg_type="SCSI"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR VPATH ESS
     if [[ -n $VPATH_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$VPATH_DASD" | grep "$disk_name "` ]]; then
       vg_type="ESSVPATH"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR 2105 ESS 
     if [[ -n $SHARK_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$SHARK_DASD" | grep "$disk_name "` ]]; then
       vg_type="ESS/2105"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR EMC
     if [[ -n $EMC_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$EMC_DASD" | grep "$disk_name "` ]]; then
       vg_type="EMC"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi 
     fi 

     ### LOOK FOR HITACHI
     if [[ -n $HITACHI_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$HITACHI_DASD" | grep "$disk_name "` ]]; then
       vg_type="HITACHI"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi
     fi

     ### LOOK FOR HITACHI/EMC/SHARK FC SCSI
     if [[ -n $FC_SCSI_DASD && $TYPE_FOUND = NO ]]; then
      if [[ -n `echo "$FC_SCSI_DASD" | grep "$disk_name "` ]]; then
       vg_type="FC_SCSI"
       if (( $vg_numb >= 1 )); then
        TYPE_FOUND=YES
       fi
      fi
     fi

    ### LOOK FOR SSA SERIAL
    if [[ -n $SSA_SERIAL && $TYPE_FOUND = NO ]]; then
     if [[ -n `echo "$SSA_SERIAL" | grep "$disk_name "` ]]; then
      vg_type="SERIAL"
      if (( $vg_numb >= 1 )); then
       TYPE_FOUND=YES
      fi
     fi
    fi

    ### ALL ELSE TYPE OF SCSI
    if [[ $TYPE_FOUND = NO ]]; then
     vg_type="UNKNOWN"
     if (( $vg_numb > 2 )); then
      TYPE_FOUND=YES
     fi
    fi 
     
   done

  vg_gb_size=`echo "scale=2; $vg_tsize / 1000" | bc` 

  ### BUILD VG ARRAY 
  if [[ $vg_name != rootvg ]]; then
   (( k = $k + 1 ))
   vg_array[$k]="$vg_name:$vg_ppsiz:$vg_tsize:$vg_numb:$vg_conca:$vg_type@$vg_hdsize"
  fi

  if [[ $SNAPSHOT = YES ]]; then
   pr -6 -t -w78 -l1 - << END | tee -a $logfile
$vg_name
$vg_ppsiz
$vg_conca
$vg_numb
$vg_type
$vg_gb_size 
END
  fi
 done

 fi

}

####################################################################
#### Needed VG array for REBUILD  excludes 'rootvg'
####################################################################
vg_needed()
{
 max_k=$k
 k=1
 trap 'rm -f /tmp/VOLUME_GROUP_REBUILD.$$ /tmp/VOLUME_GROUP_REBUILD1.$$ /tmp/SSARAID.$$; exit' 1 2 15

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 while (( $k <= $max_k )); do
  if (( `echo ${vg_array[$k]} |awk '{print $0}'|wc -c` > 1 )); then
   print "${vg_array[$k]}" >> /tmp/VOLUME_GROUP_REBUILD.$$
   # print "${vg_array[$k]}" 
  fi
   (( k = $k + 1 ))
 done
 
 if [[ -f /tmp/VOLUME_GROUP_REBUILD.$$ ]]; then
  cat /tmp/VOLUME_GROUP_REBUILD.$$ | sort -t":" -n -r -k3.1 > /tmp/VOLUME_GROUP_REBUILD1.$$

  ### PLACE SSARAID VOLUME GROUPS FIRST IN REBUILD ORDER
  if [[ -n `grep SSARAID /tmp/VOLUME_GROUP_REBUILD1.$$ 2>/dev/null` ]]; then
   grep SSARAID /tmp/VOLUME_GROUP_REBUILD1.$$ 2>/dev/null 1>/tmp/SSARAID.$$
   if (( `cat /tmp/SSARAID.$$ |wc -c` > 0 )); then
    for i in `cat /tmp/SSARAID.$$`; do
     sed -es!$i!""!g /tmp/VOLUME_GROUP_REBUILD1.$$ >/tmp/VOLUME_GROUP_REBUILD.$$
     mv /tmp/VOLUME_GROUP_REBUILD.$$ /tmp/VOLUME_GROUP_REBUILD1.$$
    done
    cat /tmp/VOLUME_GROUP_REBUILD1.$$ >> /tmp/SSARAID.$$
    mv /tmp/SSARAID.$$ /tmp/VOLUME_GROUP_REBUILD1.$$
   fi 
  fi 

  if [[ -f /tmp/VOLUME_GROUP_REBUILD1.$$ ]]; then
  k=1
   for i in `cat /tmp/VOLUME_GROUP_REBUILD1.$$`; do
    vg_array[$k]="$i"
    (( k = $k + 1 ))
   done
  fi

  max_k=$k
  if [[ $DEBUG = YES ]]; then
  k=1
  print "\n"
  while (( $k <= $max_k )); do
   if (( `echo ${vg_array[$k]} |awk '{print $0}'|wc -c` > 1 )); then
    print "${vg_array[$k]}" 
   fi
    (( k = $k + 1 ))
  done
  fi

  rm -rf /tmp/VOLUME_GROUP_REBUILD.$$
  rm -rf /tmp/VOLUME_GROUP_REBUILD1.$$
 fi

}


####################################################################
#### Identify available hdisks/vpaths for VG REBUILD 
####################################################################
find_hdd()
{
 disk_size=$1  ## PHYSICAL DISK SIZE
 disk_type=$2  ## PHYSICAL DISK TYPE
 vg_totals=$3  ## VOLUME GROUP TOTAL SIZE
 disk_numb=$4  ## PHYSICAL DISK NUMBER
 EXTEND_VG=$5  ## EXTEND VG ONLY
 extend_sz=$6  ## EXTEND SIZE
 vg_concap=$7  ## CONCURRENT CAPABLE
 if [[ -z $vg_concap ]]; then
  vg_concap=0
 fi
 hdd=0
 disk_found=0
 dasd_size=0
 dasd_found=0
 REBUILT=NO

 ####BEGIN LOOK FOR EXACT TYPE/SIZE/NUMBER OF HDD  - FIRST
 # print "DISK TYPE=$disk_type"
 # print "DISK SIZE=$disk_size"
 # print "EXTEND_SIZE=$extend_sz"
 # print "FIRST PASS" 
 # print "MAX_HDD=$max_hdd"
 while (( $hdd <= $max_hdd )); do
  if (( `echo ${hdd_avail[$hdd]} |awk '{print $0}'|wc -c` > 1 )); then
   if [[ $REBUILT != YES ]]; then
   ### FIND DISK TYPE
   if [[ $disk_type = `echo ${hdd_avail[$hdd]}|awk -F":" '{print $4}'` ]]; then
    # print "FOUND EXACT TYPE: $disk_type"
    ### FIND DISK SIZE
    dasd_found=`echo ${hdd_avail[$hdd]}|awk -F":" '{print $2}'`
    if (( $dasd_found >= $disk_size )); then
     if (( $dasd_found > $biggest_disk )); then
      biggest_disk=$dasd_found
     fi
     # print "DASD_FOUND=$dasd_found"
     # print "${hdd_avail[$hdd]}"
     disk_rebuild="$disk_rebuild `echo ${hdd_avail[$hdd]}|awk -F":" '{print $1}'`"
     hdd_avail[$hdd]=""
     (( rebuild_size = $rebuild_size + $dasd_found ))
     (( count = $count + 1 ))
     REBUILT=YES
     break
    fi 
   fi
  fi
 fi
 (( hdd = $hdd + 1 ))
 done
 waiter2
 if (( $rebuild_size >= $vg_totals )); then
  disk_found=$disk_numb
 fi
 ######END LOOK FOR EXACT SIZE AND TYPE OF HDD - FIRST

 ####BEGIN LOOK FOR TYPE/COUNT/SIZE/MULTIPLE HDISKS - SECOND
 # print "SECOND PASS" 
 # print "DISK_REBUILD=$disk_rebuild"
 fdd=$max_hdd
 while (( 0 <= $fdd )); do 
  if (( `echo ${hdd_avail[$fdd]}|awk '{print $0}'|wc -c` > 1 )); then
  if [[ $disk_type = `echo ${hdd_avail[$fdd]}|awk -F":" '{print $4}'` ]]; then

   if [[ $REBUILT != YES ]]; then
   dasd_found=`echo ${hdd_avail[$fdd]} | awk -F":" '{print $2}'`
   if (( $dasd_found <= $disk_size )); then
    if (( $dasd_found > $biggest_disk )); then
     biggest_disk=$dasd_found
    fi
     ### FIND DISK TYPE
     # print "FOUND EXACT TYPE: $disk_type"
     ### FIND DISK SIZE
     # print "${hdd_avail[$fdd]}"
     disk_rebuild="$disk_rebuild `echo ${hdd_avail[$fdd]}|awk -F":" '{print $1}'`"
     hdd_avail[$fdd]=""
     (( rebuild_size = $rebuild_size + $dasd_found ))
     (( dasd_size = $dasd_size + $dasd_found ))
     (( count = $count + 1 ))
     if (( $dasd_size >= $disk_size )); then
      REBUILT=YES
      break
     fi
   fi
   fi

  fi
  fi
  (( fdd = $fdd - 1 ))
 done
 waiter2
 if (( $rebuild_size >= $vg_totals )); then
  disk_found=$disk_numb
 fi

 #### BEGIN FIND HDD THAT ARE NOT THE RIGHT TYPE - THIRD
 # print "THIRD PASS" 
 # print "REBUILT=$REBUILT"
 # print "DISK_REBUILD=$disk_rebuild"

 #### IF CON-CAPABLE MUST BE SAME TYPE - SKIP 3rd & 4th PASS
 if (( $vg_concap == 0 )); then
 hdd=0
 while (( $hdd <= $max_hdd )); do
  if (( `echo ${hdd_avail[$hdd]} |awk '{print $0}'|wc -c` > 1 )); then
   if [[ $REBUILT != YES ]]; then
    ### FIND DISK SIZE
    dasd_found=`echo ${hdd_avail[$hdd]}|awk -F":" '{print $2}'`
    if (( $dasd_found >= $disk_size )); then
     if (( $dasd_found > $biggest_disk )); then
      biggest_disk=$dasd_found
     fi
     # print "${hdd_avail[$hdd]}"
     # print "NOT EXACT TYPE: $disk_type"
     disk_rebuild="$disk_rebuild `echo ${hdd_avail[$hdd]}|awk -F":" '{print $1}'`"
     hdd_avail[$hdd]=""
     (( rebuild_size = $rebuild_size + $dasd_found ))
     (( count = $count + 1 ))
     REBUILT=YES
     break
    fi
   fi
  fi
  (( hdd = $hdd + 1 ))
 done
 waiter2
 if (( $rebuild_size >= $vg_totals )); then
  disk_found=$disk_numb
 fi

 ####BEGIN LOOK FOR SIZE/MULTIPLE HDISKS - FOURTH
 # print "FOURTH PASS" 
 # print "REBUILT=$REBUILT"
 # print "DISK_REBUILD=$disk_rebuild"
 if [[ $REBUILT != YES ]]; then
 fdd=$max_hdd
  while (( 0 <= $fdd )); do 
  if (( `echo ${hdd_avail[$fdd]}|awk '{print $0}'|wc -c` > 1 )); then

   dasd_found=`echo ${hdd_avail[$fdd]} | awk -F":" '{print $2}'`
   # print "$dasd_found"
   # print "${hdd_avail[$hdd]}"
   # print "NOT EXACT TYPE: $disk_type"
   if (( $dasd_found <= $disk_size )); then
    if (( $dasd_found > $biggest_disk )); then
     biggest_disk=$dasd_found
    fi
    ### FIND DISK TYPE
    # print "NOT EXACT TYPE: $disk_type"
    ### FIND DISK SIZE
     disk_rebuild="$disk_rebuild `echo ${hdd_avail[$fdd]}|awk -F":" '{print $1}'`"
     hdd_avail[$fdd]=""
     (( rebuild_size = $rebuild_size + $dasd_found ))
     (( dasd_size = $dasd_size + $dasd_found ))
     (( count = $count + 1 ))
     if (( $dasd_size >= $disk_size )); then
      REBUILT=YES
      break
     fi
   fi

  fi
  (( fdd = $fdd - 1 ))
  done

 fi #REBUILT
 waiter2
 if (( $rebuild_size >= $vg_totals )); then
  disk_found=$disk_numb
 fi 
     #### END LOOK FOR SIZE/MULTIPLE HDISKS - FOURTH
 fi  #### IF CON-CAPABLE MUST BE SAME TYPE - SKIP 3rd & 4th PASS
     #### END FIND HDD THAT ARE NOT THE RIGHT TYPE
 
 # waiter2
 if (( $rebuild_size >= $vg_totals && $disk_found == $disk_numb )); then
  VGDASD="$disk_rebuild"
  REBUILT=YES
 fi

 if [[ $EXTEND_VG = YES ]]; then
  if (( $rebuild_size >= $extend_sz )); then
   VGDASD="$disk_rebuild"
   REBUILT=YES
  else
   REBUILT=NO
  fi
 fi
 ####END LOOK FOR SIZE/MULTIPLE HDISKS - FOURTH

 if [[ $REBUILT != YES && $disk_found != $disk_numb ]]; then
  if (( $vg_concap == 1 )); then
  print "\a"
  print "\a"
  print "#####################################################################"
  print "#####   NOT ENOUGH OF THE SAME TYPE HDD's AVAILABLE TO BUILD    #####"
  print "#####################################################################"
  print ""
  print "\aTYPE NEEDED: $disk_type \n"

  else

  print "\a"
  print "\a"
  print "#####################################################################"
  print "    ###### NOT ENOUGH HDD's AVAILABLE TO BUILD: $vg_name ###### "
  print "#####################################################################"
  fi
  exit 1
 fi

}


####################################################################
#### Look for existing VG first, check for correct size
####################################################################
check_existing_vg()
{
 
 vgn_reqd=""  ##  VOLUME GROUP NAME REQUIRED 
 vgn_tots=""  ##  VOLUME GROUP SIZE REQUIRED 

 ####################################################################
 #### Extend an existing VG to correct Total Size
 ####################################################################
 extend_vg()
 {
  volume_group_name=$1
  volume_group_size=$2
  volume_group_disk_type=$3
  vg_concurrent_capable=$4
  vg_name=$volume_group_name

  hdd_need_lrg=0
  hdd_need_sml=0
  largest_disk=0
  smallest_disk=99999999999
  system_disks=""
  disk_type=""
  lp_numb=0
  disk_numb=0
  vg_pp_size=0
  vg_lp_numb=0
  disk_size=0
  if [[ -z $volume_group_disk_type ]]; then
   volume_group_disk_type=""
  fi
 
  ### Find largest disk in existing VG
  existing_hdd=`lsvg -p $volume_group_name |awk '{print $1":"$2}' | grep active`
  disk_numb=`echo "$existing_hdd" |wc -l`
  disk_numb=`echo $disk_numb` 

  while (( $disk_numb > 0 )); do 
  system_disks=`lsdev -Cc disk`
  for disk_name in `echo "$existing_hdd" | awk -F":" '{print $1" "}'`; do
   disk_type=`echo "$system_disks" | grep "$disk_name "`
   ###REQUEST DISK TYPE / CHECK REBUILD TYPE
   if [[ -n `echo $disk_type|egrep "^hdisk|^vpath|^hdiskpower|^dlmfdrv"` ]]; then

   if [[ -n `echo "$disk_type" | grep SSA` ]]; then                  ## SSA DASD
    disk_size=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
    if [ -f $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE ]; then
     if (( `wc -l $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE | awk '{print $1}'` >= 1 ));then
      if [[ -n `grep "$disk_name " $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE` ]]; then
       disk_type=SSARAID
       existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
       break
      else
       disk_type=SSA
       existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
       break
      fi
     else
       disk_type=SSA
       existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
       break
     fi
    else
       disk_type=SSA
       existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
       break
    fi
   fi

   if [[ -n `echo "$disk_type"|egrep "IBM:FC:2105|IBM:2105|Data Path Optimizer|vpath"` ]]; then                                                ## ESS HDISK DASD
    ess_config=`awk ' /vpath|ESS/ {print $0}' $DRRSTDIR/DASD_FOUND.$RESTORE_DATE`
    disk_size=`echo "$ess_config" | awk -F":" ' /^'$disk_name':/ {print $2}'`
    ## CHECK AND MAKE SURE THE HDD DOESN'T BELONG TO A VPATH
    if [ `echo "$disk_name" | grep "^vpath"` ]; then                 ## ESS DASD
     if [[ -f /tmp/vpath_config.tmp ]]; then
       disk_size=`awk -F"@" '/'$disk_name'@/ {print $2}' /tmp/vpath_config.tmp`
       if [[ -n $disk_size ]]; then
        ### CHECK FOR HDD IN VPATH LATER
        disk_type=ESSVPATH
        existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
        break 
       fi
     fi
    fi

    if [[ -z `echo "$ess_vpath_disks"|egrep "$disk_name " 2>/dev/null` ]]; then
     disk_type=ESS2105
     existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
     break
    fi
   fi

   if [ `echo  $disk_name | grep "^hdiskpower"` ]; then              ## EMC DASD
     disk_size=`awk -F":" ' /'$disk_name' :/ {print $3}' $DRRSTDIR/EMC_DASD.$RES
TORE_DATE`
     if [[ -n $disk_size ]]; then  ## CHECK FOR TIMEFINDER DISKS
      disk_type=EMC
      existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
      break
     else
      disk_size=0
      disk_type=EMC
      existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
      break
     fi
   fi

   if [ `echo  $disk_name | grep "^dlmfdrv"` ]; then                  ## HITACHI
    disk_size=`awk -F":" ' /'$disk_name' :/ {print $3}' $DRRSTDIR/HITACHI_DASD.$RESTORE_DATE`
    if [[ -n $disk_size ]]; then  ## CHECK FOR TIMEFINDER DISKS
     disk_type=HITACHI
     existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
     break
    else
     disk_size=0
     disk_type=HITACHI
     existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
     break
    fi
   fi

   if [[ -n `echo "$disk_type" | grep SCSI` ]]; then                ## SCSI DASD
    disk_size=`lsattr -El $disk_name | grep size_in_mb | awk '{print $2}'`
    disk_type=SCSI
    existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
    break
   fi
  
   if (( $disk_size == 0 )); then 
    disk_type=UNKOWN
    if (( $vg_pp_size == 0 )); then
     vg_pp_size=`lsvg $volume_group_name | egrep "PP SIZE:" | awk -F":" '{print $3}' | awk '{print $1}'`
     vg_lp_numb=`lsvg -p $volume_group_name | awk ' !/'$volume_group_name':|FREE PPs/ {print $1":"$3}'` 
     lp_numb=`echo "$vg_lp_numb" | awk -F":" '/'$disk_name':/ {print $2}'`
     (( disk_size = $vg_pp_size * $lp_numb ))
     existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
     break
    else
     lp_numb=`echo "$vg_lp_numb" | awk -F":" '/'$disk_name':/ {print $2}'`
     (( disk_size = $vg_pp_size * $lp_numb ))
     existing_hdd=`echo "$existing_hdd" | sed -es!"${disk_name}:active!!g`
     break
    fi
   fi


 fi
 done
 (( disk_numb = $disk_numb - 1 ))
 if  (( $disk_size > $largest_disk )); then
  largest_disk=$disk_size
  disk_type_largest=$disk_type
 fi

 if  (( $disk_size < $smallest_disk )); then
  smallest_disk=$disk_size
  disk_type_smallest=$disk_type
 fi
 done

 if (( $largest_disk >= $smallest_disk )); then
  disk_type=$disk_type_largest
 else
  disk_type=$disk_type_smallest
 fi

  # print "LARGEST DISKS=$largest_disk"
  # print "SMALLEST DISKS=$smallest_disk"
  # print "ExistingVGSize=$existing_vgs"
  # print "VolumeGRoupSIzeNeeded=$volume_group_size"
  # print "VolumeTotalSize=$vgn_tots"
  # print "\n"
  # print "NUMBER OF DISKS NEEDED = $hdd_needed"
  # print "Size of expanded VG = $existing_vgs"
  # disk_size=$1  ## PHYSICAL DISK SIZE
  # disk_type=$2  ## PHYSICAL DISK TYPE
  # vg_totals=$3  ## VOLUME GROUP TOTAL SIZE
  # disk_numb=$4  ## PHYSICAL DISK NUMBER
  # EXTEND_VG=$5  ## EXTEND VG ONLY
  # extend_sz=$6  ## EXTEND SIZE
  # find_hdd $vg_hdsize $vg_dtype $vg_tsize $vg_numb
  # print "$largest_disk $disk_type $volume_group_size $vgs_need $hdd_needed"

  hdd_needed=1
  biggest_disk=0

  find_hdd $volume_group_size $disk_type $vgn_tots $hdd_needed YES $volume_group_size $vg_concurrent_capable
  if [[ $REBUILT = YES ]]; then

   print "\nextendvg -f $vg_name $VGDASD" | tee -a $logfile
   if [[ $CMDSO != YES ]]; then
     disk_rebuild=""
     print ""
     extendvg -f $vg_name $VGDASD 2>$DRRSTDIR/$vg_name.error 1>$DRRSTDIR/$vg_name.log
     if [ $? = 0 ]; then
      print ":${vg_name}:" >>$DRRSTDIR/VG_REBUILD.$$
      rm -f $DRRSTDIR/$vg_name.log
      rm -f $DRRSTDIR/$vg_name.error
     else
      print "\n\aProblems extending Volume Group $vg_name\n"
      cat $DRRSTDIR/$vg_name.log   | tee -a $logfile
      cat $DRRSTDIR/$vg_name.error | tee -a $logfile
      print "\nPlease fix and re-run DR Restore!\n"
      print ":${vg_name}:" >>$DRRSTDIR/VG_REBUILD.$$
      print "$vg_name" > $DRRSTDIR/$vg_name.log
      print "$vg_name" >> $DRRSTDIR/REBUILD.ERRORS
      cat $DRRSTDIR/$vg_name.error >> $DRRSTDIR/REBUILD.ERRORS
      print "" >> $DRRSTDIR/REBUILD.ERRORS
      exit 1
     fi
   fi 

  else

   print "Problems extending Volume Group $vg_name"
   print "Please check Rebuild Log!"
   print ":${vg_name}:" >>$DRRSTDIR/VG_REBUILD.$$
   print "$vg_name" > $DRRSTDIR/$vg_name.log
   print "" > $DRRSTDIR/$vg_name.error
   print "$vg_name" >> $DRRSTDIR/REBUILD.ERRORS
   cat $DRRSTDIR/$vg_name.error >> $DRRSTDIR/REBUILD.ERRORS

  fi

 }

 hdd=0
 vg_found=NO
 vgn_reqd=$1  ## VOLUME GROUP NAME REQUIRED 
 vgn_tots=$2  ## VOLUME GROUP SIZE REQUIRED 
 vg_dtype=$3  ## VOLUME GROUP DASD TYPE
 if [[ $vg_dtype = HOLDER ]]; then
  vg_dtype=""
 fi
 if [[ -z $vg_conca ]]; then
  vg_conca=0
 else
  vg_conca=$4 ## VOLUME GROUP CONCURRENT CAPABLE
 fi

 lspv | grep -w "$vgn_reqd " 2>/dev/null 1>/dev/null 
 if (( $? == 0 )); then  
  if (( $vg_conca == 1 )); then
   ### VARYON VG
   varyonvg $vgn_reqd 2>/dev/null 1>/dev/null
  fi

  vg_info=`lsvg $vgn_reqd | egrep "TOTAL PPs: |PP SIZE: "`
  existing_vgs=`echo "$vg_info"|grep "TOTAL PPs: "|awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
  existing_pps=`echo "$vg_info"|grep "PP SIZE: "|awk -F":" '{print $3}'|awk '{print $1}'`

  if  (( $existing_vgs >= $vgn_tots )); then
   print "\nFound existing VOLUME GROUP: $vgn_reqd "
   print ":${vg_name}:" >> $DRRSTDIR/VG_REBUILD.$$
   print "$vg_name:$existing_vgs:$existing_pps" >> $DRRSTDIR/VG_REBUILD.OK
   print "$vg_name" > $DRRSTDIR/$vg_name.log
   print "" > $DRRSTDIR/$vg_name.error
   vg_found="YES"
  else
   (( vgs_need = $vgn_tots - $existing_vgs ))
   print "\nVolume Group: $vgn_reqd is not large enough!  Extending by $vgs_need MB"
   if [[ -z $vg_dtype || -z $vg_conca ]]; then
   vg_dtype=`echo ${vg_array[$k]}|awk -F":" '{print $6}'|awk -F"@" '{print $1}'`
   vg_conca=`echo ${vg_array[$k]}|awk -F":" '{print $5}'`
   fi
   # print "Size_Required=$vgn_reqd"
   # print "Size_Needed=$vgs_need"
   # print "TYPE=$vg_dtype"

   extend_vg $vgn_reqd $vgs_need $vg_dtype $vg_conca
   print "" > $DRRSTDIR/$vg_name.error
   print "" > $DRRSTDIR/$vg_name.error
   print "$vg_name" > $DRRSTDIR/$vg_name.log
   vg_found="YES"
  fi

 else
  vg_found="NO"
 fi 
 
}

####################################################################
#### Identify available hdisks/vpaths for VG REBUILD 
####################################################################
rebuild_vg()
{

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/VG_REBUILD.$$ $DRRSTDIR/VG_REBUILD1.$$ $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE $DRRSTDIR/VG_REBUILD.OK; exit' 1 2 15

 rm -rf $DRRSTDIR/VG_REBUILD.OK
 rm -rf $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE
 
 if [[ -z $vg_conca ]]; then
  vg_conca=0
 fi

 k=1
 OSL=`uname -vr | awk '{print $2"."$1}'`
 #OSL=4.2 ### UNCOMMENT IF YOU WHISH TO TEST SERIAL BUILDS OF VG/LV/PS
 OSL=$(echo "scale=1; $OSL * 100" | bc)
 print ""
 if (( $OSL >= 430.0 )); then
  sep_lin3 | tee -a $logfile
  print "Rebuilding Volume Groups in Parallel!" | tee -a $logfile 
  sep_lin3 | tee -a $logfile
 fi

 while (( $k <= $max_k )); do
 VGDASD=""
 EXTEND_VG=NO
 extend_sz=0
 count=0

 if (( `echo ${vg_array[$k]}|awk '{print $0}'|wc -c` > 1 )); then
  vg_size=0
  vg_numb=0
  vg_hdsize=""

  vg_name=`echo ${vg_array[$k]}  | awk -F":" '{print $1}'`
  vg_ppsiz=`echo ${vg_array[$k]} | awk -F":" '{print $2}'`
  vg_tsize=`echo ${vg_array[$k]} | awk -F":" '{print $3}'`
  vg_numb=`echo ${vg_array[$k]}  | awk -F":" '{print $4}'`
  vg_conca=`echo ${vg_array[$k]} | awk -F":" '{print $5}'`
  vg_dtype=`echo ${vg_array[$k]}|awk -F":" '{print $6}'|awk -F"@" '{print $1}'`
  vg_physical=`echo ${vg_array[$k]}| awk -F"@" '{print $2}'`

  rebuild_size=0
  disk_rebuild=""
  biggest_disk=0
  pp_multipler=0
  REBUILT=NO

  ## CHECK FOR EXISTING VG AND SIZE 
  #print "EXISTING SIZE : $vg_name $vg_tsize"
  check_existing_vg $vg_name $vg_tsize $vg_dtype $vg_conca

  if [[ $vg_found != YES ]]; then
   print "\nRebuilding Volume Group: $vg_name \c" 
   for i in `echo $vg_physical | sed -es!";"!" "!g`; do

    vg_hdsize=`echo $i | awk -F":" '{print $2}'`
    hdd_type=`echo $i  | awk -F":" '{print $1}'`

    find_hdd $vg_hdsize $vg_dtype $vg_tsize $vg_numb NO 0 $vg_conca
    if (( $rebuild_size >= $vg_totals )); then
     # print "\nREBUILD=$rebuild_size:VGS=$vg_totals:DF\c"
     # print "=$disk_found:DN=$disk_numb:CN=$count\n"
     break
    fi

   done

   ### CHECK FOR LARGEST DISK WITHIN VG AND CHANGE PPSize ACCORDINGLY
   if (( $biggest_disk > 1016 * $vg_ppsiz )); then 
    pp_multipler=0
    while (( $biggest_disk > 1016 * $vg_ppsiz )); do
     (( vg_ppsiz = $vg_ppsiz * 2 )) 
    done
    #print "BIGGEST_DISK=$biggest_disk:PPSIZE=$vg_ppsiz"
   fi

   ### CHECK FOR LARGE ENABLE VG's
   # print "DISK_COUNT=`echo $VGDASD |wc -w`" 
   if (( $count <= 32 )); then

    ### CHECK FOR CONCURRENT ENABLE
    if (( $vg_conca == 0 )); then
     print "\nmkvg -f -y$vg_name -s$vg_ppsiz $VGDASD" | tee -a $logfile
     if [[ $CMDSO != YES ]]; then
      if (( $OSL >= 430.0 )); then

       while : ; do
       if [[ ! -n `ps -aef | grep lcreatevg | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -f /etc/security/tcbck.LCK ]]; then

        mkvg -f -y$vg_name -s$vg_ppsiz $VGDASD 2>$DRRSTDIR/$vg_name.error 1>$DRRSTDIR/$vg_name.log &
        break
       else
        sleep 1
       fi
       done

      else
       mkvg -f -y$vg_name -s$vg_ppsiz $VGDASD 2>/dev/null 1>/dev/null
       if [ $? != 0 ]; then
        print "Rebuild failure on $vg_name"
       else
        print "$vg_name" > $DRRSTDIR/$vg_name.log
        print "" > $DRRSTDIR/$vg_name.error
        print "" 
       fi
      fi
     else
      print "$vg_name" >$DRRSTDIR/$vg_name.log 
      print "" > $DRRSTDIR/$vg_name.error 
     fi
    else
     print "\nmkvg -f -y$vg_name -c -s$vg_ppsiz $VGDASD" | tee -a $logfile
     if [[ $CMDSO != YES ]]; then
      if (( $OSL >= 430.0 )); then
       while : ; do
       if [[ ! -n `ps -aef | grep lcreatevg | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -f /etc/security/tcbck.LCK ]]; then
        mkvg -f -y$vg_name -c -s$vg_ppsiz $VGDASD 2>$DRRSTDIR/$vg_name.error 1>$DRRSTDIR/$vg_name.log &  
        break
       else
        sleep 1
       fi
       done
      else
       mkvg -f -y$vg_name -c -s$vg_ppsiz $VGDASD 2>/dev/null 1>/dev/null 
       if [ $? != 0 ]; then
        print "Rebuild failure on $vg_name"
       else
        # varyonvg $vg_name
        print "$vg_name" > $DRRSTDIR/$vg_name.log
        print "" > $DRRSTDIR/$vg_name.error
        print "" 
       fi
      fi
     else
      print "$vg_name" > $DRRSTDIR/$vg_name.log
      print "" > $DRRSTDIR/$vg_name.error
     fi
    fi

   else   ### CHECK FOR LARGE ENABLE VG's

    ### CHECK FOR CONCURRENT ENABLE
    if (( $vg_conca == 0 )); then
     print "\nmkvg -B -f -y$vg_name -s$vg_ppsiz $VGDASD" | tee -a $logfile
     if [[ $CMDSO != YES ]]; then
      if (( $OSL >= 430.0 )); then
       while : ; do
       if [[ ! -n `ps -aef | grep lcreatevg | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -f /etc/security/tcbck.LCK ]]; then
        mkvg -B -f -y$vg_name -s$vg_ppsiz $VGDASD 2>$DRRSTDIR/$vg_name.error 1>$DRRSTDIR/$vg_name.log &
        break
       else
        sleep 1
       fi
       done
      else
       mkvg -B -f -y$vg_name -s$vg_ppsiz $VGDASD 2>/dev/null 1>/dev/null
       if [ $? != 0 ]; then
        print "Rebuild failure on $vg_name"
       else
        print "$vg_name" > $DRRSTDIR/$vg_name.log
        print "" > $DRRSTDIR/$vg_name.error
        print "" 
       fi
      fi
     else
      print "$vg_name" > $DRRSTDIR/$vg_name.log
      print "" > $DRRSTDIR/$vg_name.error
     fi
    else
     print "\nmkvg -B -f -y$vg_name -c -s$vg_ppsiz $VGDASD" | tee -a $logfile
     if [[ $CMDSO != YES ]]; then

      if (( $OSL >= 430.0 )); then
       while : ; do
       if [[ ! -n `ps -aef | grep lcreatevg | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -f /etc/security/tcbck.LCK ]]; then
        mkvg -B -f -y$vg_name -c -s$vg_ppsiz $VGDASD 2>$DRRSTDIR/$vg_name.error 1>$DRRSTDIR/$vg_name.log &
        break
       else
        sleep 1
       fi
       done
      else
       mkvg -B -f -y$vg_name -c -s$vg_ppsiz $VGDASD 2>/dev/null 1>/dev/null
       if [ $? != 0 ]; then
        print "Rebuild failure on $vg_name" | tee -a $logfile
       else
        print "$vg_name" > $DRRSTDIR/$vg_name.log
        print "" > $DRRSTDIR/$vg_name.error
        print "" 
       fi
      fi
     else
      print "$vg_name" > $DRRSTDIR/$vg_name.log
      print "" > $DRRSTDIR/$vg_name.error
     fi

    fi
   fi

   fi
   echo ${vg_array[$k]}|awk -F":" '{print ":"$1":"}' >> $DRRSTDIR/VG_REBUILD.$$

  fi
  (( k = $k + 1 ))
 done

}


rebuild_lvs()
{

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/VG_REBUILD.* $DRRSTDIR/VG_REBUILD1.* $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE $DRRSTDIR/VG_REBUILD.OK; exit' 1 2 15

 strp_type=""

 if [[ $CMDSO = YES ]]; then
 ### CHECK FOR ALL BUILT VOLUME GROUPS BEFORE PASSING THE 'VG_LVREBUILD' FILE
 print ""
 print "# `hostname` #" > $DRRSTDIR/REBUILD.ERRORS
 sort -u $DRRSTDIR/VG_REBUILD.$$ > $DRRSTDIR/VG_REBUILD.OK
 mv $DRRSTDIR/VG_REBUILD.OK $DRRSTDIR/VG_REBUILD.$$

 for i in `awk -F":" '{print $2}' $DRRSTDIR/VG_REBUILD.$$`; do
  if [[ -n $i ]]; then
   print "Getting size for Volume Group: $i "
   if [[ -n `lspv | grep -i "$i" 2>/dev/null` ]]; then
    vg_info=`lsvg $i | egrep "TOTAL PPs: |PP SIZE: "`
    vg_ppsiz=`echo "$vg_info"|grep "TOTAL PPs: "|\
    awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
    pp_multipler=1
    print "$i:$vg_ppsiz:$pp_multipler">>$DRRSTDIR/VG_LVBUILD.$RESTORE_DATE
   fi
  fi
 done

 else
  ### LOOK FOR VG THAT HAVE FINISHED BUILDING AND VERIFY CORRECT SIZE
  print "\n ------  Please wait!  Volume Group(s) are still rebuilding.  ------\n"
  if [[ -f $DRRSTDIR/VG_REBUILD.$$ ]]; then
  while [[ -n `cat $DRRSTDIR/VG_REBUILD.$$` ]]; do
   for i in `awk -F":" '{print $2}' $DRRSTDIR/VG_REBUILD.$$`; do
    rebuilding=`ps -aef | grep $i |egrep -v grep | egrep "mkvg|extendvg"`
    if (( `echo $rebuilding|wc -c` <= 1 )); then
     ### CHECK ERROR LOG FOR VG
     if [[ -f $DRRSTDIR/$i.error && -f $DRRSTDIR/$i.log ]]; then
      if [[ -n `egrep "Making|physical|wait" $DRRSTDIR/$i.error` ]]; then
       changed=`grep changed $DRRSTDIR/$i.log`
       if [[ -n $changed ]]; then
       egrep -v "$changed" $DRRSTDIR/$i.log > $DRRSTDIR/$i.log.tmp
       mv $DRRSTDIR/$i.log.tmp $DRRSTDIR/$i.log
       egrep -v "Making|physical|wait" $DRRSTDIR/$i.error>$DRRSTDIR/$i.error.tmp
       mv $DRRSTDIR/$i.error.tmp $DRRSTDIR/$i.error
       fi
      fi
      VG_ERROR=`wc -l $DRRSTDIR/$i.error | awk '{print $1}'` 
      VG_BLD=`wc -l $DRRSTDIR/$i.log | awk '{print $1}'` 
      if (( $VG_ERROR >= 1 && $VG_BLD == 0 )); then
       print "\aError rebuilding/extending $i!  Check rebuild log!\n"
       sed -es!":$i:"!""!g $DRRSTDIR/VG_REBUILD.$$ > $DRRSTDIR/VG_REBUILD1.$$
       mv $DRRSTDIR/VG_REBUILD1.$$ $DRRSTDIR/VG_REBUILD.$$
       cat $DRRSTDIR/$i.error | tee -a $logfile
       rm -f $DRRSTDIR/$i.error $DRRSTDIR/$i.log
      else
       if [[ $i = `cat $DRRSTDIR/$i.log` ]]; then
        sed -es!":$i:"!""!g $DRRSTDIR/VG_REBUILD.$$ > $DRRSTDIR/VG_REBUILD1.$$
        mv $DRRSTDIR/VG_REBUILD1.$$ $DRRSTDIR/VG_REBUILD.$$
  
        ### CHECK ACTUAL REBUILD SIZE AGAINST REQUIRED SIZE
        k=1
        while (( $k <= $max_k )); do
         if (( `echo ${vg_array[$k]} |awk '{print $0}'|wc -c` > 1 )); then
          vg_name=`echo ${vg_array[$k]}  | awk -F":" '{print $1}'`
          vg_ppsiz=`echo ${vg_array[$k]} | awk -F":" '{print $2}'`
          vg_tsize=`echo ${vg_array[$k]} | awk -F":" '{print $3}'`
          vg_conca=`echo ${vg_array[$k]} | awk -F":" '{print $5}'`
          ### CHECK FOR CON-CURRENT CAPABLE VG
          if (( $vg_conca == 1 )); then
           ### VARYON VG
           if [[ $CMDSO != YES ]]; then
            print "\nVaryon ON VG: \t$vg_name \n" | tee -a $logfile
            print "varyonvg $vg_name" >> $logfile
            varyonvg $vg_name  
            if [ $? != 0 ]; then
             print "VG: $vg_name FAILED to 'varyonvg'"
             print "Vary Volume Group on manually,  then re-run 'dr_restore.sh'"
             exit 1
            fi
           else 
            print "varyonvg $vg_name" | tee -a $logfile 
           fi
          fi

          if [[ $i = $vg_name ]]; then
          if [[ -f $DRRSTDIR/VG_REBUILD.OK ]]; then
          existing_vgs=`awk -F":" '/^'$i':/ {print $2}' $DRRSTDIR/VG_REBUILD.OK`
          existing_pps=`awk -F":" '/^'$i':/ {print $3}' $DRRSTDIR/VG_REBUILD.OK`
          if [[ ! -n $existing_vgs ]]; then
           vg_info=`lsvg $i | egrep "TOTAL PPs: |PP SIZE: "`
           existing_vgs=`echo "$vg_info"|grep "TOTAL PPs: "|\
           awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
           existing_pps=`echo "$vg_info"|grep "PP SIZE: "|
           awk -F":" '{print $3}'|awk '{print $1}'`
          fi
          else
           vg_info=`lsvg $i | egrep "TOTAL PPs: |PP SIZE: "`
           existing_vgs=`echo "$vg_info"|grep "TOTAL PPs: "|\
           awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
           existing_pps=`echo "$vg_info"|grep "PP SIZE: "|
           awk -F":" '{print $3}'|awk '{print $1}'`
          fi

          if (( $existing_vgs >= $vg_tsize )); then
           print "VG build complete:  $i" | tee -a $logfile
           vg_array[$k]="" 
           ### CHECK FOR CHANGE IN PP SIZE
           if (( $vg_ppsiz < $existing_pps )); then
            (( pp_multipler = $existing_pps / $vg_ppsiz ))
            (( vg_ppsiz = $vg_ppsiz * $pp_multipler ))
            # print "PP Multipler: $pp_multipler -- PP Size for $vg_name: $vg_ppsiz \n"
           fi

           ### PASS VG/LV PARAMETERS FOR LV BUILD ROUTINES
           print "$vg_name:$vg_ppsiz:$pp_multipler" >> $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE
           rm -f $DRRSTDIR/$i.error $DRRSTDIR/$i.log
           break 2
          else
           print "\a\nVG: $vg_name DOES NOT MEET TOTAL SIZE REQUIREMENTS!"
           rm -f $DRRSTDIR/$i.error $DRRSTDIR/$i.log
           print "ATTEMPTING TO EXTEND VG!"

           if [[ $DEBUG = YES ]]; then
           #### RUN 'dr_restore.sh w/ -b' IF YOU WHISH TO SEE HDD AVAIL AFTER BUILD
           print "AVAILABLE HDDS"
           hdd=0
           while (( $hdd < $max_hdd )); do
            if (( `echo ${hdd_avail[$hdd]}|awk '{print $0}'|wc -c` > 1 )); then
             print "${hdd_avail[$hdd]}"
            fi
            (( hdd = $hdd + 1 ))
           done
           fi

            disk_rebuild=""
            check_existing_vg $i $vg_tsize HOLDER $vg_conca
            if [[ $REBUILT = YES ]]; then
             ### CHECK FOR CHANGE IN PP SIZE
             if (( $vg_ppsiz < $existing_pps )); then
             (( pp_multipler = $existing_pps / $vg_ppsiz ))
             (( vg_ppsiz = $vg_ppsiz * $pp_multipler ))
             # print "PP Multipler: $pp_multipler"
              print "PP Size for $vg_name: $vg_ppsiz"
             fi

             print "$vg_name:$vg_ppsiz:$pp_multipler" >>$DRRSTDIR/VG_LVBUILD.$RESTORE_DATE
             break

            else
             print "\aPlease fix and re-run DR Restore!\n"
             print ":${vg_name}" >>$DRRSTDIR/VG_REBUILD.$$
             print "$vg_name" > $DRRSTDIR/$vg_name.log
             if [[ $REBUILT != YES ]]; then
              rm -f $DRRSTDIR/$i.error $DRRSTDIR/$i.log
              sed -es!":$i:"!""!g $DRRSTDIR/VG_REBUILD.$$>$DRRSTDIR/VG_REBUILD1.$$
              mv $DRRSTDIR/VG_REBUILD1.$$ $DRRSTDIR/VG_REBUILD.$$
              break
             fi

            fi
           fi
           
          fi
         fi
        (( k = $k + 1 ))
        done
        
       fi
      fi
      
     fi
    fi 
   done 
  done
 fi
 fi 

 ### CLEAR OUT LOGICAL VOLUME INFO FROM PREVIOUS RUNS
 if [[ -d $DRRSTDIR/Logical_Volumes ]]; then
  rm -f $DRRSTDIR/Logical_Volumes/*.sh $DRRSTDIR/Logical_Volumes/*.fs
  rm -f $DRRSTDIR/Logical_Volumes/*.commands
 fi

 rm -rf $DRRSTDIR/VG_REBUILD.$$
 rm -rf $DRRSTDIR/VG_REBUILD.OK

}

disk_avail()
{

 trap 'rm -f $DRRSTDIR/DISKS_AVAIL1$$ $DRRSTDIR/DISKS_AVAIL$$; exit' 1 2 15

 if [[ -f $DRRSTDIR/DASD_FOUND.$RESTORE_DATE ]]; then
  cat $DRRSTDIR/DASD_FOUND.$RESTORE_DATE | sort -t":" -n -k1.6 > $DRRSTDIR/DISKS_AVAIL1.$$
 fi

 ### PULL OUT HDD's THAT BELONG TO A VOLUME GROUP AND/OR SPARE PDISKS
 for i in `lspv | egrep -v "none |None " | awk '{print $1}'`; do
  awk ' !/'$i':/ {print $0}' $DRRSTDIR/DISKS_AVAIL1.$$> $DRRSTDIR/DISKS_AVAIL.$$
  mv $DRRSTDIR/DISKS_AVAIL.$$ $DRRSTDIR/DISKS_AVAIL1.$$
 done 

 if [[ -f $DRRSTDIR/DISKS_AVAIL1.$$ ]]; then
 awk '! /SSARAID-SPARE/ {print $0}' $DRRSTDIR/DISKS_AVAIL1.$$ > $DRRSTDIR/DISKS_AVAIL.$$
 mv $DRRSTDIR/DISKS_AVAIL.$$ $DRRSTDIR/DISKS_AVAIL1.$$
 hdd=0
  for i in `cat $DRRSTDIR/DISKS_AVAIL1.$$`; do
   hdd_avail[$hdd]="$i"
   (( hdd = $hdd + 1 ))
  done
 fi
 max_hdd=$hdd
 ### CLEAR LAST ARRAY POSITION
 (( hdd = $max_hdd + 1 ))
 hdd_avail[$hdd]=""
 (( hdd = $max_hdd - 1 ))
 max_hdd=$hdd

 if [[ $DEBUG = YES ]]; then
  print "\nDASD Available for re-build!"
  max_hdd=$hdd
  hdd=0
  while (( $hdd <= $max_hdd )); do
   if (( `echo ${hdd_avail[$hdd]} |awk '{print $0}'|wc -c` > 1 )); then
    print "${hdd_avail[$hdd]}"
   fi
   (( hdd = $hdd + 1 ))
  done
  print "\n"
  # print "MAX_HDD's=$max_hdd"
 fi

 rm -rf $DRRSTDIR/DISKS_AVAIL.$$
 rm -rf $DRRSTDIR/DISKS_AVAIL1.$$
}

################################################################################
# BUILD LOGICAL VOLUMES, must have *.rebuild file to work
################################################################################
build_logical_volume()
{
 k=0
 lv_name=''
 lv_ppsz=''
 lv_vgnm=''
 lv_type=''
 lv_lpnb=0
 lv_lptl=0
 lv_disk=0
 lv_mntp=''
 tot_size=0
 gb_tot_size=0
 NOBUILD=$2

 trap 'rm -f $DRRSTDIR/LVREBUILD.* $DRRSTDIR/LVREBUILD1.* $DRRSTDIR/PAGING_SPACES.* $DRRSTDIR/Logical_Volumes/*.paging_space $DRRSTDIR/Logical_Vlumes/*.commands; exit' 1 2 15

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 LVMES=`awk '/^LOGICAL_VOLUME_INFO:/ {print $0}' $RBLD |sed -es!"LOGICAL_VOLUME_INFO:"!!g | sed -es!";"!" "!g`

 if (( $DR_SNAP_VER > 240 )); then
  FILESYSTEMS=`awk ' /^FS_INFO:/ {print $0}' $RBLD | sed -es!"FS_INFO:"!!g | awk -F":" '{print $1" :"$2":"$3":"$4":"$5":"$6":"$7":"$8":"$9":"$10":"}' | sort -t":" -u -d -k1`
  FILESYSTEMS=`echo "$FILESYSTEMS" | sed -es!" "!!g`
 fi

 build_mklv_cmds()
 {
 lv_upper=5000
 #JFS #JFS2
 if [[ $lv_type = jfs || $lv_type = jfs2 ]]; then
 
  if (( $lv_lpnb == $lv_lptl )); then    #NON COPY

   if [[ ! -n $lv_stpw ]]; then          #NON STRIPE / NON COPY
    if (( $lv_lpnb >=5000 )); then
     (( lv_upper = $lv_lpnb + 1 ))
    fi
    mklv_build="mklv -y$lv_name -t$lv_type -L$lv_mntp -x$lv_upper $lv_vgnm $lv_lpnb"
 
   else                                  #STRIPE / NON COPY
 
    lv_stpd=`echo "$lv_stpd"|sed -es!"-"!" "!g` 
    mklv_build="mklv -y$lv_name -t$lv_type -L$lv_mntp -S$lv_stpw $lv_vgnm $lv_lpnb $lv_stpd"
   fi
 
  else
   if [[ ! -n $lv_stpw ]]; then          #NON STRIPE / COPY
    if (( $lv_lpnb >=5000 )); then
     (( lv_upper = $lv_lpnb + 1 ))
    fi
    mklv_build="mklv -y$lv_name -t$lv_type -L$lv_mntp -x$lv_upper -c 2 $lv_vgnm $lv_lpnb"
   else                        	        #STRIPE / COPY
    lv_stpd=`echo "$lv_stpd"|sed -es!"-"!" "!g` 
    mklv_build="mklv -y$lv_name -t$lv_type -L$lv_mntp -u$lv_stpn -S$lv_stpw -c 2 $lv_vgnm $lv_lpnb $lv_stpd"
   fi
 
  fi
 
 fi
 }
 
 if [[ -n $LVMES ]]; then 
 print "\n" >> $logfile
 clear
 print_ver
 sep_line >> $logfile
 print "Verifying that Logical Volume(s) are needed for 'REBUILD'.\n"|tee -a $logfile
 print "Please wait!\n"

 rm -f $DRRSTDIR/LVREBUILD.* $DRRSTDIR/PAGING_SPACES.*

 ### EXCLUDE VOLUME GROUPS GOES HERE 
 if [[ -f /tmp/EXCLUDE ]]; then
   sep_lin3 | tee -a $logfile
   print "\aUSING EXCLUDE FILE!  '/tmp/EXCLUDE'" | tee -a $logfile
   print "Excluding Logical Volume(s) from Volume Group(s):  \c"|tee -a $logfile
   h=5
   for i in `echo "$exclude_vg"|sed -es!":"!""!g`; do
    print "$i \c" | tee -a $logfile
    (( h = $h + 1 ))
    if (( $h == 7 )); then
     h=0
     print ""
    fi
   done
   print "" | tee -a $logfile
   sep_lin3 | tee -a $logfile
   print "" | tee -a $logfile
 fi
 ### END EXCLUDE VOLUME GROUPS ENDS HERE

 for i in $exclude_vg; do
  vgname=`echo "$i" | awk -F":" '{print $2":"}'`
  LVMES=`echo "$LVMES" | awk ' ! /^'${vgname}'/ {print $0}'`
 done

 echo "$LVMES" | awk -F":" ' {
 lv_vgnm=1
 lv_ppsz=2
 lv_name=3
 lv_type=4
 lv_lpnb=5
 lv_lptl=6
 lv_disk=7
 lv_mntp=8
 lv_stpn=9
 lv_stpw=10
 lv_stpd=11
 PPSIZE =$2
 LVSIZE =$5
 gb_tot_size=0
 
 tot_size = PPSIZE * LVSIZE
 small = tot_size / 1000
 small=int(small)

if ( small <= 0.0 )
 {
  gb_tot_size = tot_size / 1000
  gb_tot_size=substr(gb_tot_size,2,length(gb_tot_size)-1)

  {printf("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s",$lv_vgnm,$lv_ppsz,$lv_name,$lv_type,$lv_lpnb,$lv_lptl,$lv_disk,$lv_mntp,gb_tot_size,$lv_stpn,$lv_stpw,$lv_stpd)}
 }
   else
 {
  gb_tot_size = tot_size / 1000
 {printf("%s:%s:%s:%s:%s:%s:%s:%s:%.0d:%s:%s:%s",$lv_vgnm,$lv_ppsz,$lv_name,$lv_type,$lv_lpnb,$lv_lptl,$lv_disk,$lv_mntp,gb_tot_size,$lv_stpn,$lv_stpw,$lv_stpd)
 }
 }
 printf "\n" }' >> $DRRSTDIR/LVREBUILD.$$ 

 ### SORT LV's FROM LARGEST TO SMALLEST
 if [[ -f $DRRSTDIR/LVREBUILD.$$ ]]; then
  sed -es!" "!!g $DRRSTDIR/LVREBUILD.$$ > $DRRSTDIR/LVREBUILD1.$$
  sort -t":" -r -n -k9 $DRRSTDIR/LVREBUILD1.$$ > $DRRSTDIR/LVREBUILD.$$
  rm -f $DRRSTDIR/LVREBUILD1.$$

 if [[ $SNAPSHOT = YES ]]; then
  sep_lin3 | tee -a $logfile
  pr -4 -t -w78 -l1 - << END | tee -a $logfile
LV Name
LV Type
FS Mnt Pt
  Size(GB)
END
  sep_lin3 | tee -a $logfile

  for i in `cat $DRRSTDIR/LVREBUILD.$$`; do
   lv_vgnm=`echo $i | awk -F":" '{print $1}'`
   lv_ppsz=`echo $i | awk -F":" '{print $2}'`
   lv_name=`echo $i | awk -F":" '{print $3}'`
   lv_type=`echo $i | awk -F":" '{print $4}'`
   lv_lpnb=`echo $i | awk -F":" '{print $5}'`
   lv_lptl=`echo $i | awk -F":" '{print $6}'`
   lv_disk=`echo $i | awk -F":" '{print $7}'`
   lv_mntp=`echo $i | awk -F":" '{print $8}'`
   gb_tot_size=`echo $i | awk -F":" '{print $9}'`
   lv_stpw=`echo $i | awk -F":" '{print $10}'`
   lv_stpn=`echo $i | awk -F":" '{print $11}'`
   lv_stpd=`echo $i | awk -F":" '{print $12}'`

   (( k = $k + 1 ))
   lv_array[$k]="$lv_vgnm:$lv_ppsz:$lv_name:$lv_type:$lv_lpnb:$lv_lptl:$lv_disk:$lv_mntp:$gb_tot_size:$lv_stpn:$lv_stpw:$lv_stpd"

   pr -4 -t -w78 -l1 - << END | tee -a $logfile
$lv_name
$lv_type
$lv_mntp
  $gb_tot_size
END
  done

  max_k=$k
  if [[ $DEBUG = YES ]]; then
   ### IF YOU WHISH TO SEE LV_ARRAY
   print "LV ARRAY"
   k=1
   while (( $k <= $max_k )); do
    if (( `echo ${lv_array[$k]} |awk '{print $0}'|wc -c` > 1 )); then
     print "${lv_array[$k]}"
    fi
    (( k = $k + 1 ))
   done
  fi
 print ""
 fi

 if [[ $NOBUILD != nobuild ]]; then

 if [[ ! -d $DRRSTDIR/Logical_Volumes ]]; then
  mkdir -p $DRRSTDIR/Logical_Volumes
 fi

 # VOLUMEGRP_PP=$1  #Volume Group Physical Partition Size
 # VOLUMEGRP_MP=$2  #Volume Group Physical Partition Multipler
 
 if [[ -f $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE ]]; then
  # cat $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE
  VOLUME_GROUPS=`cat $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE`
  if [[ -n $VOLUME_GROUPS ]]; then
   print "Logical Volume(s), Paging Space(s), and Filesystem(s) rebuilding!\n" 
  fi

 for i in `cat $DRRSTDIR/VG_LVBUILD.$RESTORE_DATE`; do
  MIRROR=NO
  strip_w=""
  strip_tmp=""
  lv_old_ppsz=0

  vgnm=`echo "$i" | awk -F":" '{print $1}'`
  VOLUMEGRP_PP=`echo "$i" | awk -F":" '{print $2}'`
  VOLUMEGRP_MP=`echo "$i" | awk -F":" '{print $3}'`
  awk ' /^'$vgnm':/ {print $0}' $DRRSTDIR/LVREBUILD.$$>$DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD
  sort -t":" -n -r -k6 $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD > $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD1.$$
  mv $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD1.$$ $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD

  if [[ -f $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD && -n `cat $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD 2>/dev/null 1/dev/null` ]]; then 
  print "# REBUILD COMMANDS FOR VOLUME GROUP $vgnm\n" > $DRRSTDIR/Logical_Volumes/$vgnm.commands

  for j in `cat $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD`; do
   waiter2
   strip_w=""
   lv_vgnm=`echo $j | awk -F":" '{print $1}'`
   lv_ppsz=`echo $j | awk -F":" '{print $2}'`
   lv_name=`echo $j | awk -F":" '{print $3}'`
   lv_type=`echo $j | awk -F":" '{print $4}'`
   lv_lpnb=`echo $j | awk -F":" '{print $5}'`
   lv_lptl=`echo $j | awk -F":" '{print $6}'`
   lv_disk=`echo $j | awk -F":" '{print $7}'`
   lv_mntp=`echo $j | awk -F":" '{print $8}'`
   gb_tot_size=`echo $j | awk -F":" '{print $9}'`
   lv_stpn=`echo $j | awk -F":" '{print $10}'`
   lv_stpw=`echo $j | awk -F":" '{print $11}'`
   lv_stpd=`echo $j | awk -F":" '{print $12}'`
   lv_ownr=`echo $j | awk -F":" '{print $13}'`

   ### IF File Systems, remove entry from /etc/filesystems
   if [[ -n $lv_mntp && $lv_mntp != N/A ]]; then
    print "rmfs -r $lv_mntp 2>/dev/null 1>/dev/null" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     
    if [[ ! -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.Success ]]; then
     if [[ $CMDSO != YES ]]; then
     rmfs -r $lv_mntp 2>/dev/null 1>>$logfile
     fi
    else
     if [[ ! -n `awk ' /Re-built: '$lv_name' / {print $0}' $DRRSTDIR/Logical_Volumes/$lv_vgnm.Success` ]]; then
      print "Logical Volume: $lv_name for filesystem: $lv_mntp already built" >> $logfile 
     fi
    fi
   fi

   ### CHECK FOR MIRROR
   if (( $lv_lpnb != $lv_lptl )); then
    MIRROR=YES
   fi

   ### CHECK FOR Strip Width
   if (( $DR_SNAP_VER > 240 )); then

    strip_w=`echo "$lv_stpw" | sed -es!"-S"!!g`

   else ##OLD SUPPORT FOR VERSIONS PRIOR TO 2.46

    if (( $lv_disk > 1 )); then
     strip_w=`awk ' /mklv/ {print $0}' $CMDS | awk ' /-y'$lv_name' / {print $0}' | awk ' /-S/ {print $0}' | sort -u`
     if [[ -n $strip_w ]]; then
      strip_tmp=`echo "$strip_w" | awk '{print $5,$6}'`
      for k in $strip_tmp; do
       if [[ -n `echo "$k" | awk ' /-S/ {print $0}'` ]]; then
        strip_w=`echo "$k" | sed -es!"-S"!""!g`
        break
       fi
      done
     fi
    fi

   fi

   ### CHECK FOR LV TYPES THAT ARE NOT JFS/JFSLOG/PAGING/SYSDUMP/BOOT
   if [[ $lv_type != jfs && $lv_type != jfslog && $lv_type != paging && $lv_type != jfs2 && $lv_type != jfs2log  && $lv_type != sysdump && $lv_type != boot ]]; then
    lv_type=jfs
   fi

   ### MAKE Logical Volume
   if [[ $lv_type = jfs || $lv_type = jfs2 ]]; then
    # VOLUMEGRP_PP=$1  #Volume Group Physical Partition Size
    # VOLUMEGRP_MP=$2  #Volume Group Physical Partition Multipler
    ### BUILD STATEMENTS for Logical Volume

   if (( $DR_SNAP_VER > 240 )); then

     if [[ -n $lv_stpw ]]; then
      build_mklv_cmds
     else 
      build_mklv_cmds
     fi

   else
     mklv_build=`awk ' /mklv -y'$lv_name' / {print $0}' $CMDS | sort -u`
   fi

    ### CHECK PP SIZE AND MAKE SURE THAT IT HASN'T CHANGED W/ VG BUILD
    if (( $lv_ppsz != $VOLUMEGRP_PP )); then
     lv_old_ppsz=$lv_ppsz
     lv_old_lpnb=$lv_lpnb
     (( lv_ppsz = $lv_ppsz * $VOLUMEGRP_MP ))
     if (( $lv_lpnb % 2 )); then  ### ENSURE ROUNDING UP OF #LP's
      (( lv_lpnb = $lv_lpnb + 1 ))
     fi
     ## TEST TO SEE IF #LV's WILL BE AT LEAST AS BIG WHEN RECREATED
     (( lv_nsiz = $lv_lpnb / $VOLUMEGRP_MP )) 
     if (( $lv_nsiz != 0 )); then  ## MAKE SURE NO ZERO LP SIZE
      if (( $lv_nsiz * $VOLUMEGRP_MP < $lv_old_lpnb )); then
       (( lv_lpnb = $lv_old_lpnb + $VOLUMEGRP_MP ))
      fi
     fi

     (( lv_lpnb = $lv_lpnb / $VOLUMEGRP_MP )) 
     if (( $lv_lpnb == 0 )); then
      lv_lpnb=1
     fi

     mklv_tmp=`echo "$mklv_build" | sed -es!"$lv_vgnm $lv_old_lpnb"!"$lv_vgnm $lv_lpnb"!g`

     if [[ -n $strip_w ]]; then

      if (( $DR_SNAP_VER > 240 )); then
       mklv_disks=`echo "$lv_stpd" | sed -es!"-"!" "!g`
      else
       mklv_disks=`echo "$mklv_tmp"| awk -F"-S$strip_w" '{print $2}'|awk -F"$lv_vgnm" '{print $2}'|awk -F" $lv_lpnb " '{print $2}'`
      fi

      actual_disks=`lspv | awk ' /'$lv_vgnm'/ {print $1}'`
      disk_count=`echo "$actual_disks"|wc -l`
      actual_disks=`echo $actual_disks`
      disk_count=`echo $disk_count`

      if (( $disk_count == $lv_disk )); then
       mklv_build=`echo "$mklv_tmp" | sed -es!"$mklv_disks"!" $actual_disks"!g` 
       print "$mklv_build" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
      else if (( $disk_count > $lv_disk )); then
       ### FIND JUST $lv_disk
       disks=""
       count=0
       for l in $actual_disks; do
        (( count = $count + 1 ))
        if (( $count <= $lv_disk )); then
         disks="$disks $l" 
        else
         break
        fi
       done

       mklv_build=`echo "$mklv_tmp" | sed -es!"$mklv_disks"!" $disks"!g` 
       print "$mklv_build" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
       
      else if (( $disk_count >= 2 )); then
       ### FIND JUST $actual_disks
       mklv_build=`echo "$mklv_tmp" | sed -es!"$mklv_disks"!" $actual_disks"!g` 
       print "$mklv_build" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands

      else
       ### BUILD W/O STRIPE 
       mklv_build=`echo "$mklv_tmp" | sed -es!"$mklv_disks"!""!g|sed -es!"-S$strip_w"!""!g`
       print "$mklv_build" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
      fi
      fi
      fi

     else
      print "$mklv_tmp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     fi

    else   ### LV PP SIZE IS THE SAME AS VG PP SIZE

     if [[ -n $strip_w ]]; then

      if (( $DR_SNAP_VER > 240 )); then
       mklv_disks=`echo "$lv_stpd" | sed -es!"-"!" "!g`
      else 
       mklv_disks=`echo "$mklv_build"| awk -F"-S$strip_w" '{print $2}'|awk -F"$lv_vgnm" '{print $2}'|awk -F" $lv_lpnb " '{print $2}'`
      fi

      actual_disks=`lspv | awk ' /'$lv_vgnm'/ {print $1}'`
      disk_count=`echo "$actual_disks"|wc -l`
      actual_disks=`echo $actual_disks`
      disk_count=`echo $disk_count`

      if (( $disk_count == $lv_disk )); then
       mklv_tmp=`echo "$mklv_build" | sed -es!"$mklv_disks"!" $actual_disks"!g` 
       print "$mklv_tmp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands

      else if (( $disk_count > $lv_disk )); then
       ### FIND JUST $lv_disk
       disks=""
       count=0
       for l in $actual_disks; do
        (( count = $count + 1 ))
        if (( $count <= $lv_disk )); then
         disks="$disks $l" 
        else
         break
        fi
       done

       mklv_tmp=`echo "$mklv_build" | sed -es!"$mklv_disks"!" $disks"!g` 
       print "$mklv_tmp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
       
      else if (( $disk_count >= 2 )); then
       ### FIND JUST $actual_disks
       mklv_tmp=`echo "$mklv_build" | sed -es!"$mklv_disks"!" $actual_disks"!g` 
       print "$mklv_tmp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands

      else
       ### BUILD W/O STRIP 
       mklv_tmp=`echo "$mklv_build" | sed -es!"$mklv_disks"!""!g|sed -es!"-S$strip_w"!""!g`
       print "$mklv_tmp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands

      fi
      fi
      fi

    else
     print "$mklv_build" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
    fi 

   fi
   fi

   ### CRFS FILE SYSTEMS  (GEN COMMANDS ONLY)
   if (( $DR_SNAP_VER > 240 )); then
    filesystems=`echo "$FILESYSTEMS" | awk ' /:'$lv_name':/ {print $0}'`
    if [[ -n $lv_mntp && $lv_mntp != "N/A" || -n $filesystem ]]; then

     ### MAKE DIRECTORIES
     print "mkdir -p $lv_mntp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
 
     fs_type=`echo "$filesystems" | awk -F":" '{print $2}'`
     fs_ag=`echo "$filesystems"   | awk -F":" '{print $3}'`
     fs_nbpi=`echo "$filesystems" | awk -F":" '{print $4}'`
     fs_frag=`echo "$filesystems" | awk -F":" '{print $5}'`
     fs_bf=`echo "$filesystems"   | awk -F":" '{print $6}'`
     fs_inl=`echo "$filesystems"  | awk -F":" '{print $7}'`
     fs_opt=`echo "$filesystems"  | awk -F":" '{print $8}'`
     fs_own=`echo "$filesystems"  | awk -F":" '{print $9}'`
 
     if [[ $fs_type = jfs ]]; then ## JFS
      print "crfs -vjfs -d"$lv_name" -m"$lv_mntp" -Ayes -prw -tno -a frag="$fs_frag" -a nbpi="$fs_nbpi" -a bf="$fs_bf" -a ag="$fs_ag"" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
 
     else                          ## JFS2
     
      if [[ $fs_inl = no ]]; then
       print "crfs -vjfs2 -d"$lv_name" -m"$lv_mntp" -Ayes -prw -a options="$fs_opt" -a agblksize="$fs_ag"" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
      else
       print "crfs -vjfs2 -d"$lv_name" -m"$lv_mntp" -Ayes -prw -a options="$fs_opt" -a agblksize="$fs_ag" -a logname=INLINE" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
      fi 
     fi
 
     ### MOUNT THE FILESYSTEMS
     print "mount $lv_mntp"    >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     
     ### CHANGE OWNER SHIP ACL
     print "chown $fs_own $lv_mntp">>$DRRSTDIR/Logical_Volumes/$vgnm.commands
    else
     print "chown $lv_ownr $lv_mntp">>$DRRSTDIR/Logical_Volumes/$vgnm.commands
    fi
 
   else

    filesystem=`awk ' /^crfs / {print $0}' $CMDS | awk ' /'$lv_name' / {print $0}' | sort -u` 
    if [[ -n $lv_mntp && $lv_mntp != "N/A" || -n $filesystem ]]; then
    
     ### MAKE DIRECTORIES
     if [[ -n $lv_mntp ]]; then
      # mkdir -p $lv_mntp
      print "mkdir -p $lv_mntp" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     else
      mount_pt=`awk ' /^crfs / {print $0}' $CMDS | awk ' /'$lv_name' / {print $0}' | awk -F"-m" '{print $2}' | awk '{print $1}'|sort -u`
      mkdir -p $mount_pt
      print "mkdir -p $mount_pt" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     fi
 
     print "$filesystem" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
 
     ### MOUNT THE FILESYSTEMS
     mntfs=`awk ' /^mount / {print $0}' $CMDS | egrep "$lv_mntp"|sort -u`
     if [[ -n $mntfs ]]; then
      print "$mntfs" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     else
      #mntfs=`awk ' /^mount / {print $0}' $CMDS | egrep "$mount_pt"`
      mntfs=`awk ' /^mount / {print $0}' $CMDS | egrep "$mount_pt"|sort -u`
      print "$mntfs" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     fi
 
     ### CHANGE OWNER SHIP ACL
     ownership=`awk ' /^chown / {print $0}' $CMDS | egrep "$lv_mntp"|sort -u`
     if [[ -n $ownership ]]; then
      print "$ownership" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     else
      ownership=`awk ' /^chown / {print $0}' $CMDS | egrep "$mount_pt"|sort -u`
      print "$ownership" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     fi
    else
     ownership=`awk ' /^chown / {print $0}' $CMDS | egrep "$lv_name"|sort -u`
     if [[ -n $ownership ]]; then
      print "$ownership" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
     fi
    fi
   fi ## NEW FS_INFO VER > 240

   if [[ $lv_type = jfslog || $lv_type = jfslog2 ]]; then  ### Check for MIRRORED JFS LOG
    # print "JFSLOG"
    if [[ $MIRROR = YES ]]; then
     print "recovery_disks=\"\"">$DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
     print "log_lv=\"\""      >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
     print "recovery_disks=\`lspv |grep \"$lv_vgnm \" | awk '{print \$1}'\`" >>$DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
     print "log_lv=\`lsvg -l $lv_vgnm | grep jfslog | awk '{print \$1}'\`" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
     print "mklvcopy -k \$log_lv 2 \$recovery_disks" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
    fi
   fi

   ### CHECK FOR PAGING SPACES
   if [[ $lv_type = paging ]]; then
    waiter2
    # print "PAGING"
    if (( $lv_ppsz != $VOLUMEGRP_PP )); then
     lv_old_ppsz=$lv_ppsz
     lv_old_lpnb=$lv_lpnb
     (( lv_ppsz = $lv_ppsz * $VOLUMEGRP_MP ))
     if (( $lv_lpnb % 2 )); then  ### ENSURE ROUNDING UP OF #LP's
      (( lv_lpnb = $lv_lpnb + 1 ))
     fi
     ## TEST TO SEE IF #LV's WILL BE AT LEAST AS BIG WHEN RECREATED
     (( lv_nsiz = $lv_lpnb / $VOLUMEGRP_MP )) 
     if (( $lv_nsiz != 0 )); then  ## MAKE SURE NO ZERO LP SIZE
      if (( $lv_nsiz * $VOLUMEGRP_MP < $lv_old_lpnb )); then
       (( lv_lpnb = $lv_old_lpnb + $VOLUMEGRP_MP ))
      fi
     fi

     (( lv_lpnb = $lv_lpnb / $VOLUMEGRP_MP )) 
     if (( $lv_lpnb == 0 )); then
      lv_lpnb=1
     fi
    fi

    if [[ $MIRROR = YES ]]; then
     print "recovery_disks=\"\"">$DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
     print "recovery_disks=\`lspv |grep \"$lv_vgnm \" | awk '{print \$1}'\`" >>$DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
     print "mkps -n -a -s $lv_lpnb $vgnm '\`echo \$recovery_disks\`' | tee 1>/tmp/page_built" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
     print "mklvcopy -k \`cat /tmp/page_built\` 2 \$recovery_disks" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging

    else

     print "recovery_disks=\"\"">$DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
     print "recovery_disks=\`lspv |grep \"$lv_vgnm \" | awk '{print \$1}'\`" >>$DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
     print "mkps -n -a -s $lv_lpnb $vgnm '\`echo \$recovery_disks\`'" >> $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
    fi

   print "$lv_vgnm:$lv_ppsz:$lv_name:$lv_lpnb:$lv_lptl:$MIRROR" >> $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE
   fi  ## PAGING SPACE

  done
  fi

  ### COPY JFSLOG CMDS INTO CMDS FILE
  if [[ -f $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog ]]; then
   cat $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
   rm -f $DRRSTDIR/Logical_Volumes/$vgnm.commands.jfslog
  fi

  ### COPY PAGING SPACE CMDS INTO CMDS FILE
  if [[ -f $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging ]]; then
   cat $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging >> $DRRSTDIR/Logical_Volumes/$vgnm.commands
   rm -f $DRRSTDIR/Logical_Volumes/$vgnm.commands.paging
  fi

  rm -f $DRRSTDIR/Logical_Volumes/$vgnm.LV_REBUILD 

 done
 fi 
 fi
 fi
 fi

}

build_logical_volume_cmds()
{
 trap 'rm -f $DRRSTDIR/Logical_Volumes/*.sh $DRRSTDIR/Logical_Volumes/*.fs $DRRSTDIR/Logical_Volumes/*.commands $DRRSTDIR/LVREBUILD.*; exit' 1 2 15

 if [[ -f $DRRSTDIR/LVREBUILD.$$ ]]; then

  sort -t":" -u -k1.12 $DRRSTDIR/LVREBUILD.$$ > $DRRSTDIR/LVREBUILD.$$.TMP
  mv -f $DRRSTDIR/LVREBUILD.$$.TMP $DRRSTDIR/LVREBUILD.$$
  for i in `sort -t":" -r -n -k5.1 $DRRSTDIR/LVREBUILD.$$`; do
   lv_vgnm=`echo "$i" | awk -F":" '{print $1}'`
   Logical_Volumes=`echo "$i" | awk -F":" '{print $3":"$4":"$5":"$6}'`
   for j in $Logical_Volumes; do

    lv_name=`echo "$j" | awk -F":" '{print $1}'`
    # print "LV_NAME=$lv_name"
    lv_type=`echo "$j" | awk -F":" '{print $2}'`

    if [[ -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands && $lv_type = jfs || $lv_type = jfs2 ]]; then
     awk ' /^mklv / {print $0}' $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands | awk ' /-y'$lv_name' / {print $0}' >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
    else
    ### PAGING SPACE BUILDS
    if [[ -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands && $lv_type = paging ]]; then
    egrep "^$lv_vgnm:" $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE | egrep ":$lv_name:" > $DRRSTDIR/Logical_Volumes/$lv_vgnm.$lv_name.paging_space
    else
     ### ALL OTHER TYPES 
     if [[ -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands && $lv_type != paging && $lv_type != jfslog && $lv_type != jfs && $lv_type != jfs2 && $lv_type != jfs2log ]]; then
      awk ' /^mklv / {print $0}' $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands | awk ' /-y'$lv_name' / {print $0}' >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
     fi
    fi
   fi
   done
  done

  ### FILESYSTEM REBUILDS 
  filesystems=""
  filesystems=`awk ' /:jfs:|:jfs2:/ {print $0}' $DRRSTDIR/LVREBUILD.$$ |awk ' !/:N\/A:/ {print $0}' | sort -t":" -r -n -k8`

  for i in $filesystems; do
   failure=""
   lv_vgnm=`echo $i | awk -F":" '{print $1}'`
   lv_ppsz=`echo $i | awk -F":" '{print $2}'`
   lv_name=`echo $i | awk -F":" '{print $3}'`
   lv_type=`echo $i | awk -F":" '{print $4}'`
   lv_lpnb=`echo $i | awk -F":" '{print $5}'`
   lv_lptl=`echo $i | awk -F":" '{print $6}'`
   lv_disk=`echo $i | awk -F":" '{print $7}'`
   lv_mntp=`echo $i | awk -F":" '{print $8}'`
   gb_tot_size=`echo $i | awk -F":" '{print $9}'`

   failure=`awk ' /^mklv / {print $0}' $DRRSTDIR/REBUILD.ERRORS | awk ' /'$lv_name' / {print $0}'`
   if [[ -n $failure ]]; then
    print "Cannot create filesystem: $lv_mntp  " | tee -a $logfile
    print "Failed to build Logical volume: $lv_name" | tee -a $logfile
    print ""
   else
    ## MAKE DIRECTORY
    mk_dir=`awk ' /^crfs / {print $0}' $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands | awk ' /-d'$lv_name' / {print $0}' | awk -F"-m" '{print $2}' | awk '{print $1}'`
    print "mkdir -p $mk_dir" >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
    ## CREATE FILESYSTEM 
    awk ' /^crfs / {print $0}' $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands | awk ' /-d'$lv_name' / {print $0}' >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
    print "mount $mk_dir" >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
    ## CHANGE OWERSHIP
    egrep " $mk_dir" $DRRSTDIR/Logical_Volumes/$lv_vgnm.commands | egrep -v "rmfs|crfs|mklv|mkdir|mount" > $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp 
    ## CHECK FOR MULTIPLES W/ SAME DIRECTORY NAME INBEDDED
    if (( `wc -l $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp | awk '{print $1}'` > 1 )); then
     IFS_TMP="$IFS"
     IFS="
"
     directory=""
     while read line; do
      directory=`echo $line | awk '{print $3}'`
      if [[ $directory = $mk_dir ]]; then
       print "$line" >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
      fi
     done < $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp
     IFS="$IFS_TMP"
     rm -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp
    else
     cat $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp >> $DRRSTDIR/Logical_Volumes/$lv_vgnm.sh
     rm -f $DRRSTDIR/Logical_Volumes/$lv_vgnm.tmp
    fi
   fi
 
  done

  ### GET VOLUME GROUPS/LOGICAL W/ FILESYSTEMS
  if [[ -d $DRRSTDIR/Logical_Volumes ]]; then
   cd $DRRSTDIR/Logical_Volumes
   filesystems=`egrep -l "^crfs" *.commands`
   if [[ -n $filesystems ]]; then 
   if [[ -f $DRRSTDIR/Logical_Volumes/FILESYSTEMS ]]; then
    rm -f $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE
   fi
   for fsn in "$filesystems"; do
    ### SORT THE DIRECTORIES IN DECENDING ORDER... SUB Dirs UNDER ROOT Dirs 
    for z in `cat $fsn | awk ' /^crfs / {print $4":"$3}'`; do
     waiter2
     lv_name=`echo "$z" | awk -F":" '{print $2}' | awk -F"-d" '{print $2}'`
     lv_mntp=`echo "$z" | awk -F":" '{print $1}' | awk -F"-m" '{print $2}'`
     print "$lv_mntp: $lv_name" >> $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE
    done  
   done  
   sort -t":" -d -k1 $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE | sed -es!" "!!g > $DRRSTDIR/Logical_Volumes/FILESYSTEMS.TMP
   mv $DRRSTDIR/Logical_Volumes/FILESYSTEMS.TMP $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE

   for i in `cat $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE`; do
    waiter2
    lv_name=`echo "$i" | awk -F":" '{print $2}'` 
    vg_name=`fgrep -l "y$lv_name " *.commands | awk -F"." '{print $1}'`
    lv_mntp=`echo "$i"|awk -F":" '{print $1}'`
    filesystem=`egrep "d$lv_name " $vg_name.commands | egrep "$lv_mntp " | awk ' /^crfs/ {print $0}'`

    print "$filesystem 1>>$logfile" > /$DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
    chmod 755 /$DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
   done
   fi
  fi

  if [[ -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS ]]; then
   rm -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
  fi

 fi 
 rm -f $DRRSTDIR/LVREBUILD.$$
}

start_mklv()
{

trap 'rm -f $DRRSTDIR/VG_REBUILD.* $DRRSTDIR/VG_LVBUILD.* $DRRSTDIR/LVREBUILD.$$ $DRRSTDIR/Logical_Volumes/*.error $DRRSTDIR/Logical_Volumes/*.sh $DRRSTDIR/Logical_Volumes/*.Success $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE $DRRSTDIR/Logical_Volumes/*.paging_space $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS $DRRSTDIR/Logical_Volumes/CHACL $DRRSTDIR/Logical_Volumes/*.log $DRRSTDIR/Logical_Volumes/*.fs $DRRSTDIR/Logical_Volumes/build_lvs.* $DRRSTDIR/Logical_Volumes/*.stripe $DRRSTDIR/Logical_Volumes/MIRRORED.VGS; exit' 1 2 15

if [[ ! -f $DRRSTDIR/Logical_Volumes ]]; then
 mkdir -p $DRRSTDIR/Logical_Volumes
fi

LV_SETTINGS=""
FS_SETTINGS=""

 ### ERROR HANDLER FOR MKLV/MKPS COMMANDS
 error_control()
 {
 if [[ -n `ps -aef | egrep "mklv " | egrep -v grep` || -n `ps -aef | egrep "mkps " | egrep -v grep` ]]; then
  print "\nWaiting for all Logical Volume(s) to build!  Please wait!\n"

  while [[ -n `ps -aef | egrep "mklv " | egrep -v grep` || -n `ps -aef | egrep "mkps " | egrep -v grep` ]]; do
   sleep 3
  done
 fi

 cd $DRRSTDIR/Logical_Volumes
 ls *.error 2>/dev/null 1>/dev/null
 if (( $? == 0 )); then
  for i in `ls *.error|sort`; do
  VG_NAME=`echo $i | awk -F"." '{print $1}'`
  LV_NAME=`echo $i | awk -F"." '{print $2}'`
  LV_TYPE=`echo $i | awk -F"." '{print $3}'`
  ### PAGING SPACE BUILDS
  if [[ $LV_TYPE = paging ]]; then
   if [[ ! -n `cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error` ]]; then
   print "Re-built: $LV_NAME "|tee -a $DRRSTDIR/Logical_Volumes/$VG_NAME.Success
   if [[ `egrep "^$VG_NAME:" $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE | egrep ":$LV_NAME:" | awk -F":" '{print $6}'` = YES ]]; then
    print "$LV_NAME:MIRROR:\c" > $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.paging
    cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.log >>$DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.paging 
    else
    print "$LV_NAME::\c" > $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.paging
    cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.log >>$DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.paging 

   fi
   
   else
   print "\aBUILD FAILURE: $LV_NAME "|tee -a $DRRSTDIR/Logical_Volumes/$LV_NAME.$LV_TYPE.error
   print "Please check $DRRSTDIR/REBUILD.ERRORS for FAILURE code!"
   print " " >> $DRRSTDIR/REBUILD.ERRORS
   cat $DRRSTDIR/Logical_Volumes/$LV_NAME.$LV_TYPE.error >> $DRRSTDIR/REBUILD.ERRORS
   cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error >> $DRRSTDIR/REBUILD.ERRORS
   print " " >> $DRRSTDIR/REBUILD.ERRORS
   sleep 6
  fi
   
  else  
  ### JFS LVs BUILDS 
  if [[ ! -n `cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error` ]]; then
   print "Re-built: $LV_NAME "|tee -a $DRRSTDIR/Logical_Volumes/$VG_NAME.Success
  else
   ### CHECK FOR STRIP LV's w/ 4.3.2 WARNING
   if [[ -n `egrep "WARNING|imported|4.3.2" $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error 2>/dev/null` ]]; then
   print "Re-built: $LV_NAME "|tee -a $DRRSTDIR/Logical_Volumes/$VG_NAME.Success
   else 
   print "\a\nBUILD FAILURE: $LV_NAME "|tee -a $DRRSTDIR/Logical_Volumes/$LV_NAME.$LV_TYPE.error
   print "Please check $DRRSTDIR/REBUILD.ERRORS for FAILURE code!\n"
   print " " >> $DRRSTDIR/REBUILD.ERRORS
   cat $DRRSTDIR/Logical_Volumes/$LV_NAME.$LV_TYPE.error >> $DRRSTDIR/REBUILD.ERRORS
   cat $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error >> $DRRSTDIR/REBUILD.ERRORS
   print " " >> $DRRSTDIR/REBUILD.ERRORS
   # sleep 4 ## OLD SETTING IF SYNC PROBLEM ARISE CHANGE BACK
   sleep 2
   fi
  fi
  fi
 
  rm -f $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.error $DRRSTDIR/Logical_Volumes/$VG_NAME.$LV_NAME.$LV_TYPE.log

  done
 fi

 rm -f $DRRSTDIR/Logical_Volumes/*.error $DRRSTDIR/Logical_Volumes/*.log

 }

 ### ROUTINE ADDED TO FIX MIRRORED LV's ON 1 SPINDLE
 find_mirror_dasd()
 {
  trap 'rm -f $DRRSTDIR/Logical_Volumes/MIRRORED.VGS $DRRSTDIR/Logical_Volumes/MIRRORED.VGS.TMP $DRRSTDIR/Logical_Volumes/*.mirror $DRRSTDIR/Logical_Volumes/*.sh $DRRSTDIR/Logical_Volumes/build*.* $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS $DRRSTDIR/Logical_Volumes/*.log $DRRSTDIR/Logical_Volumes/*.error $DRRSTDIR/Logical_Volumes/*.Success; exit' 1 2 15

  ### File Name for mklv
  mirror_vg=$1  # VOLUME GROUP
  mirror_lv=$2  # LOGICAL VOLUME
  spindle=0
  mirror_size=0
  mirror_dasd=""
  
  ## CHECK FOR AT LEAST 2 SPINDLES
  if [[ -f $DRRSTDIR/Logical_Volumes/MIRRORED.VGS ]]; then
   spindle=`awk -F":" ' /'$mirror_vg':/ {print $2}' $DRRSTDIR/Logical_Volumes/MIRRORED.VGS`
   if [[ ! -n $spindle ]]; then  
    spindle=`lspv |egrep "$mirror_vg " | awk '{print $1}' | wc -l `
    print "$mirror_vg:$spindle" >> $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
   fi
  else
   spindle=`lspv |egrep "$mirror_vg " | awk '{print $1}' | wc -l `
   print "$mirror_vg:$spindle" >> $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
  fi

  if (( $spindle < 2 )); then
   print "\nWARNING!  Not enough PHYSICAL VOLUMES to mirror LV: $mirror_lv" | tee -a $logfile
   print "\n Would you like to:"
   print " 1. Extend the Volume Group and then rebuild the Logical Volume."
   print " 2. Convert the Logical Volume to a NON-mirrored LV."
   print " 3. Ignore and rebuild the Logical Volume manually."
   print " >\c" 
   while read input; do
     case $input in
      1) print "\nPlease wait, extending Volume Group: $mirror_vg!" 
         # disk_avail  ## REINDEX AVAILABLE DASD
         vg_info=`lsvg $mirror_vg | egrep "TOTAL PPs: |PP SIZE: |Concurrent: "`
         existing_vgs=`echo "$vg_info"|grep "TOTAL PPs: "|awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
         vg_conca=`echo "$vg_info" | egrep "Concurrent: "` 
         if [[ -n $vg_conca ]]; then
          vg_conca=1
         else
          vg_conca=0
         fi
         strp_type=SSA
 
         mirror_dasd=`lsvg -p $mirror_vg 2>/dev/null | egrep -v "PV_NAME" |egrep -v "$mirror_vg:" | awk '{print $1}'`
         if [[ -n $mirror_dasd ]]; then
          mirror_size=`awk -F":" ' /'$mirror_dasd':/ {print $2}' $DRRSTDIR/DASD_FOUND.$RESTORE_DATE`
         else
          print "ERROR QUERYING PHYSICAL VOLUMES FOR VG: $mirror_vg" | tee -a $DRRSTDIR/REBUILD.ERRORS
          exit 1
         fi

         (( vgs_need = $mirror_size + $existing_vgs ))

         ### CHECK VG TYPE
         strp_disk_type=`lsdev -Cc disk | egrep "$mirror_dasd "`
         if ( echo $strp_disk_type|grep -i SSA 2>/dev/null 1>/dev/null); then
          strp_type=SSA
         fi 
         if ( echo $strp_disk_type|grep -i SCSI 2>/dev/null 1>/dev/null); then
          strp_type=SCSI
         fi 
         if ( echo $strp_disk_type|egrep -i "2105" 2>/dev/null 1>/dev/null)
          then
          strp_type=ESSVPATH
         fi
         if ( echo $strp_disk_type|egrep -i "hdiskpower|EMC" 2>/dev/null 1>/dev/null); then
          strp_type=EMC
         fi 
         if ( echo $strp_disk_type|egrep -i "dlmfdr|Hitachi" 2>/dev/null 1>/dev/null); then
          strp_type=HITACHI
         fi
         if ( echo $strp_disk_type|egrep -i "FC SCSI Disk" 2>/dev/null 1>/dev/null); then
          strp_type=FC_SCSI
         fi

         VGDASD="" 
         disk_rebuild=""
         check_existing_vg $mirror_vg $vgs_need $strp_type $vg_conca

         if [[ -f $DRRSTDIR/Logical_Volumes/MIRRORED.VGS ]]; then
          spindle=`awk -F":" ' /'$mirror_vg':/ {print $2}' $DRRSTDIR/Logical_Volumes/MIRRORED.VGS`
          if [[ ! -n $spindle ]]; then  
           spindle=`lspv |egrep "$mirror_vg " | awk '{print $1}' | wc -l `
           print "$mirror_vg:$spindle" >> $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
          else
           spindle_tmp=`lspv |egrep "$mirror_vg " | awk '{print $1}' | wc -l `
           spindle=`awk ' /'$mirror_vg':/ {print $2}' $DRRSTDIR/Logical_Volumes/MIRRORED.VGS`
           sed -es!"$spindle"!"$spindle_tmp"!g $DRRSTDIR/Logical_Volumes/MIRRORED.VGS > $DRRSTDIR/Logical_Volumes/MIRRORED.VGS.TMP
           mv $DRRSTDIR/Logical_Volumes/MIRRORED.VGS.TMP $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
          fi
          spindle=`lspv |egrep "$mirror_vg " | awk '{print $1}' | wc -l `
          print "$mirror_vg:$spindle" > $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
         fi
         break ;;
      2) print "\nConverting to non-mirrored Logical Volume!\n"
         sed -es!" -c 2"!""!g $DRRSTDIR/Logical_Volumes/build_lvs.$lv > $DRRSTDIR/Logical_Volumes/build_lvs.$lv.tmp
         mv $DRRSTDIR/Logical_Volumes/build_lvs.$lv.tmp $DRRSTDIR/Logical_Volumes/build_lvs.$lv
         break ;;
  3|I|i) print "\nIgnoring WARNING!  Rebuild with existing DASD for Volume: $mirror_vg \n"
         break ;;
      *) ;;
     esac
     printf "\a\a Enter 1, 2, 3, or I"
     print " > \c"
   done

  fi

 }

 ### ROUTINE ADDED TO FIX MULTIPLE STRIPPED LV's W/I VG
 find_stripe_dasd()
 {

  trap 'rm -f $DRRSTDIR/Logical_Volumes/*.stripe $DRRSTDIR/Logical_Volumes/*.stripe*.tmp $DRRSTDIR/Logical_Volumes/yes.* $DRRSTDIR/Logical_Volumes/*.Success $DRRSTDIR/Logical_Volumes/*.log $DRRSTDIR/Logical_Volumes/*.error $DRRSTDIR/LVREBUILD.$$; exit' 1 2 15

  ### File Name for mklv
  stripe_vg=$1  # VOLUME GROUP
  stripe_lv=$2  # LOGICAL VOLUME
  stripe_mr=$3  # MIRRORED STRIPPED LOGICAL VOLUME
  stripe_fn=$4  # MKLV BUILD FILENAME
  stripe_cc=$5  # LV CONCURRENT CAPABLE
  stripe_wd=0   # STRIPE WIDTH (i.e. NUMBER OF LP's per DISKS)

  ### CHECK FORM MIRRORED STRIP LV
  if [[ $stripe_mr = NO ]]; then
   stripe_lp=`awk -F"-S" '{print $2}' $stripe_fn | awk '{print $3}'`
   stripe_disk=`awk -F"-S" '{print $2}' $stripe_fn |\
   awk '{ for ( i = 4; i <= NF; i++ )
    {printf("%s ", $i)}
   }`
   disk_count=`echo "$stripe_disk"|wc -w`
   disk_count=`echo $disk_count`
  else
   stripe_lp=`awk -F"-S" '{print $2}' $stripe_fn | awk '{print $5}'`
   stripe_disk=`awk -F"-c" '{print $2}' $stripe_fn |\
    awk '{ for ( i = 4; i <= NF; i++ )
    {printf("%s ", $i)}
   }`
   disk_count=`echo "$stripe_disk"|wc -w`
   disk_count=`echo $disk_count`
  fi

  stripe_disk=`echo $stripe_disk`

  ### LOOK FOR STANDARD AND STRIPED LV's in same VOLUME_GROUPS
  if [[ ! -f $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe ]]; then
  if [[ -n `ps -aef | egrep "mklv " |egrep "$stripe_vg" | egrep -v grep` ]]; then
   print "\nPlease wait!  Finding all available PPs for volume group:$stripe_vg\n"
   while [[ -n `ps -aef | egrep "mklv " | egrep "$stripe_vg" | egrep -v grep` ]]; do
    sleep 3
   done
    lsvg -p $i | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
  else
    lsvg -p $i | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
  fi
  fi

  if [[ ! -f $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe ]]; then 
   lsvg -p $i | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
   ### MAKE COPY TO PARSE
   cp -fp $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp
  else
   ### MAKE COPY TO PARSE
   cp -fp $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp
  fi

  ## IF DISKCOUNT > ACTUAL DISKS TRY BUILDING ON ACTUALS FIRST BEFORE ADD HDD's
  actual_hd=0

  actual_hd=`wc -l $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp | awk '{print $1}'`
  z_disks=$actual_hd

  if (( $actual_hd >= 2 )); then       ### TRY BUILD ON DISK NUMBER NEEDED FIRST
   orig_disk_count=$disk_count
   (( stripe_wd = $stripe_lp / $disk_count ))
   if (( $stripe_wd == 0 )); then
    stripe_wd=1
   fi

   while (( $z_disks >= 2 )); do 
    built=0
    strp_cnt=0

    for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
     strp_disk=`echo "$z" | awk -F":" '{print $1}'`
     strp_size=`echo "$z" | awk -F":" '{print $2}'`
  
     if (( $strp_size >= $stripe_wd )); then
      (( strp_cnt = $strp_cnt + 1 ))
      if (( $strp_cnt == $disk_count )); then       ### STRIPE ON MIN OF 2-HDD's
 
       disk_count=$disk_count
       while (( ( $stripe_lp % $disk_count ) > 0 )); do
        (( stripe_lp = $stripe_lp + 1 ))
       done
       
       if [[ $stripe_mr = YES ]]; then             ## CHECK FOR MIRRORED STRIPE
        if (( ( $disk_count % 2 ) > 0 )); then
         (( disk_count = $disk_count + 1 ))
        fi
       fi
       built=1
       lsvg -p $i | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
       break 2

      fi
     fi
    done
    (( z_disks = $z_disks - 1 ))
   done
  fi
  
   ### TRY BUILDING ON (( DISK_COUNT - 1 )) on SECOND PASS
  if (( $actual_hd >= 2 )); then
   if (( $built == 0 )); then
   disk_count=$actual_hd
   if (( $disk_count >= 2 )); then
   while (( $disk_count >= 2 )); do
    (( stripe_wd = $stripe_lp / $disk_count ))
    if (( $stripe_wd == 0 )); then
     stripe_wd=1
    fi

     z_disks=$actual_hd
     while (( $z_disks >= 2 )); do 
      built=0
      strp_cnt=0
      for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
       strp_disk=`echo "$z" | awk -F":" '{print $1}'`
       strp_size=`echo "$z" | awk -F":" '{print $2}'`
  
       if (( $strp_size >= $stripe_wd )); then
        (( strp_cnt = $strp_cnt + 1 ))
        if (( $strp_cnt == $disk_count )); then    ### STRIPE ON MIN OF 2-HDD's
 
         disk_count=$disk_count
         while (( ( $stripe_lp % $disk_count ) > 0 )); do
          (( stripe_lp = $stripe_lp + 1 ))
         done
       
         if [[ $stripe_mr = YES ]]; then            ## CHECK FOR MIRRORED STRIPE
          if (( ( $disk_count % 2 ) > 0 )); then
           (( disk_count = $disk_count + 1 ))
          fi
         fi
        built=1
        lsvg -p $i | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
        break 3

        fi
       fi

      done
     (( z_disks = $z_disks - 1 ))
     done
     (( disk_count = $disk_count - 1 ))
    done
    fi

   fi
  fi

  ### STRIPPED LPs PER DISK
  (( stripe_wd = $stripe_lp / $disk_count ))
  if (( $stripe_wd == 0 )); then
    stripe_wd=1
  fi
  strp_cnt=0
  strp_dasd=""
  strp_disk=""
  strp_left=0
  strp_size=0
  strp_built=NO

  for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
   strp_disk=`echo "$z" | awk -F":" '{print $1}'`
   strp_size=`echo "$z" | awk -F":" '{print $2}'`

   if (( $strp_size >= $stripe_wd )); then
    (( strp_cnt = $strp_cnt + 1 ))
    strp_dasd="$strp_dasd $strp_disk"
    (( strp_left = $strp_size - $stripe_wd ))

    sed -es!"$strp_disk:$strp_size"!"$strp_disk:$strp_left"!g $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
    cp -f $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp

    ### STRIPE ON MIN OF 2-HDD's
    if (( $strp_cnt == $disk_count && $disk_count >= 2 )); then    

     strp_dasd=`echo $strp_dasd` 
     sed -es!"$stripe_disk"!"$strp_dasd"!g $stripe_fn > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe$$.tmp 
     mv $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe$$.tmp $stripe_fn

     if [[ $stripe_mr = NO ]]; then
      cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
      ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log &
      strp_built=YES
      sleep 1
      break
     else
       print "y\n
 " > $DRRSTDIR/Logical_Volumes/yes.$lv
       sleep 1
       cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
       ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv < $DRRSTDIR/Logical_Volumes/yes.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log &
       strp_built=YES
       sleep 2
       rm -f $DRRSTDIR/Logical_Volumes/yes.$lv
       break
     fi

    fi 
   fi
  done

  ### CHECK FOR ACTUAL BUILDING OF STRIPPED LV's
  if [[ $strp_built = NO ]]; then
   print "\a\n BUILD FAILURE!  NOT ENOUGH FREE PP's IN VOLUME GROUP: $stripe_vg! " | tee -a $logfile
   print "\a  - OR DISKS ARE NOT LARGE ENOUGH TO HOLD STRIPPED LOGICAL VOLUME!"|tee -a $logfile
   print "\n Would you like to: \n"
   print " 1. Extend VG: $stripe_vg"
   print " 2. Convert logical volume: '$stripe_lv' to a non-stripped LV."
   print " 3. Ignore, fix manually? (Note, 'dr_restore' will continue to run!)"
   print "\n Enter 1, 2, 3, or I. "
   print " > \c"
   while read input; do
     case $input in
      1) print "\nPlease wait, calculating needed PPs!" 
         # disk_avail  ## REINDEX AVAILABLE DASD
         vg_info=`lsvg $stripe_vg | egrep "TOTAL PPs: |PP SIZE: |Concurrent: "`
         existing_vgs=`echo "$vg_info"|grep "TOTAL PPs: "|awk -F":" '{print $3}'|awk '{print $2}'|sed -es!"("!""!g`
         existing_pps=`echo "$vg_info"|grep "PP SIZE: "|awk -F":" '{print $3}'|awk '{print $1}'`
         vg_conca=`echo "$vg_info" | egrep "Concurrent: "` 
         if [[ -n $vg_conca ]]; then
          vg_conca=1
         else
          vg_conca=0
         fi
         strp_type=SSA
         (( vgs_need = $stripe_wd * $existing_pps + $existing_vgs ))

         ### CHECK VG TYPE
         for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
          strp_disk=`echo "$z" | awk -F":" '{print $1}'`
          strp_disk_type=`lsdev -Cc disk | egrep "$strp_disk "`
          if ( echo $strp_disk_type|grep -i SSA 2>/dev/null 1>/dev/null); then
           strp_type=SSA
           break
          fi 
          if ( echo $strp_disk_type|grep -i SCSI 2>/dev/null 1>/dev/null); then
           strp_type=SCSI
           break
          fi 
          if ( echo $strp_disk_type|egrep -i "2105" 2>/dev/null 1>/dev/null)
           then
           strp_type=ESSVPATH
           break
          fi
          if ( echo $strp_disk_type|egrep -i "hdiskpower|EMC" 2>/dev/null 1>/dev/null); then
           strp_type=EMC
           break
          fi 
          if ( echo $strp_disk_type|egrep -i "dlmfdr|Hitachi" 2>/dev/null 1>/dev/null); then
           strp_type=HITACHI
           break
          fi
          if ( echo $strp_disk_type|egrep -i "FC SCSI Disk" 2>/dev/null 1>/dev/null); then
           strp_type=FC_SCSI
           break
          fi
         done

         rm -f $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe

         VGDASD="" 
         disk_rebuild=""
         check_existing_vg $stripe_vg $vgs_need $strp_type $vg_conca
         if [[ $REBUILT = YES ]]; then
          rm -f $DRRSTDIR/$stripe_vg.log
          rm -f $DRRSTDIR/$stripe_vg.error
         fi

         lsvg -p $stripe_vg | egrep -v "$stripe_vg:" | awk ' /active/ {print $1":"$4}' > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
         cp -fp $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp
         disk_count=$orig_disk_count
         actual_hd=`awk -F":" '{print $1}' $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp | wc -l`
         actual_hd=`echo $actual_hd`

        ### TRY BUILDING ON (( DISK_COUNT - 1 )) on SECOND PASS
        disk_count=$orig_disk_count
        if (( $actual_hd >= 2 )); then
        if (( $disk_count >= 2 )); then
        while (( $disk_count >= 2 )); do
         (( stripe_wd = $stripe_lp / $disk_count ))
         if (( $stripe_wd == 0 )); then
          stripe_wd=1
         fi

         z_disks=$actual_hd
         while (( $z_disks >= 2 )); do 
          built=0
          strp_cnt=0
          for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
           strp_disk=`echo "$z" | awk -F":" '{print $1}'`
           strp_size=`echo "$z" | awk -F":" '{print $2}'`
  
           if (( $strp_size >= $stripe_wd )); then
            (( strp_cnt = $strp_cnt + 1 ))
            if (( $strp_cnt == $disk_count )); then ### STRIPE ON MIN OF 2-HDD's
 
             disk_count=$disk_count
             while (( ( $stripe_lp % $disk_count ) > 0 )); do
              (( stripe_lp = $stripe_lp + 1 ))
             done
       
             if [[ $stripe_mr = YES ]]; then        ## CHECK FOR MIRRORED STRIPE
              if (( ( $disk_count % 2 ) > 0 )); then
               (( disk_count = $disk_count + 1 ))
              fi
             fi
             built=1
             break 3
          fi
         fi

        done
        (( z_disks = $z_disks - 1 ))
       done
       (( disk_count = $disk_count - 1 ))
      done
     fi
    fi

    ### STRIPPED LPs PER DISK
    (( stripe_wd = $stripe_lp / $disk_count ))
    if (( $stripe_wd == 0 )); then
      stripe_wd=1
    fi
    strp_cnt=0
    strp_dasd=""
    strp_disk=""
    strp_left=0
    strp_size=0
    strp_built=NO

    for z in `cat $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe`; do 
     strp_disk=`echo "$z" | awk -F":" '{print $1}'`
     strp_size=`echo "$z" | awk -F":" '{print $2}'`

     if (( $strp_size >= $stripe_wd )); then
      (( strp_cnt = $strp_cnt + 1 ))
      strp_dasd="$strp_dasd $strp_disk"
      (( strp_left = $strp_size - $stripe_wd ))

      sed -es!"$strp_disk:$strp_size"!"$strp_disk:$strp_left"!g $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
      cp -f $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp

      ### STRIPE ON MIN OF 2-HDD's
      if (( $strp_cnt == $disk_count && $disk_count >= 2 )); then    

       strp_dasd=`echo $strp_dasd` 
       sed -es!"$stripe_disk"!"$strp_dasd"!g $stripe_fn > $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe$$.tmp 
       mv $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe$$.tmp $stripe_fn

       if [[ $stripe_mr = NO ]]; then
        cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
        ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log &
        strp_built=YES
        sleep 1
        break
       else
        print "y\n
 " > $DRRSTDIR/Logical_Volumes/yes.$lv
        sleep 1
        cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
        ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv < $DRRSTDIR/Logical_Volumes/yes.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log &
        strp_built=YES
        sleep 2
        rm -f $DRRSTDIR/Logical_Volumes/yes.$lv
        break
      fi

     fi 
    fi
   done
   strp_built=NO
   print "\nFAILED TO BUILD STRIPPED LOGICAL VOLUME: $j\n"
   break;;

      2) print "\n Converting to standard Logical Volume\n"
         stripe_blks=`awk -F"-S" '{print $2}' $stripe_fn | awk '{print $1}'`
         sed -es!"-S$stripe_blks"!"-x5000"!g $stripe_fn > $stripe_fn.tmp
         vg_disks=`lspv | grep $stripe_vg | awk '{print $1}'`
         sed -es!"$stripe_disk"!" `echo $vg_disks`"!g $stripe_fn.tmp>$stripe_fn
         if [[ $stripe_mr = YES ]]; then
          stripe_upp=`awk -F"-u" '{print $2}' $stripe_fn | awk '{print $1}'`
          sed -es!"-u$stripe_upp"!""!g $stripe_fn > $stripe_fn.tmp
          mv -f $stripe_fn.tmp $stripe_fn
         fi
         chmod 755 $stripe_fn
         print "CHANGING TO:" >> $logfile
         cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
         print ""
         ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log &
         strp_built=YES
         sleep 1
         break ;;

  3|I|i) break;;
      *) ;;
     esac
     printf "\a\a Enter 1, 2, 3, or I"
     print " > \c"
   done

  else
   mv $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe.tmp $DRRSTDIR/Logical_Volumes/$stripe_vg.stripe
  fi

 }

 cd $DRRSTDIR/Logical_Volumes

 lv=0
 LV_SIZE=0
 LV_STRP=""
 LV_MIRR=""
 MKLV_STRP=""
 MKLV_MIRR=""
 for lvs in `ls *.paging_space 2>/dev/null`; do
   VG_NAME=`echo "$lvs" | awk -F"." '{print $1}'`
   PS_NAME=`echo "$lvs" | awk -F"." '{print $2}'`
   page_size=`cat $lvs  | awk -F":" '{print $4}'`
   MIRROR=`cat $DRRSTDIR/Logical_Volumes/$lvs | awk -F":" '{print $6}'`
   lv_type=paging
   ### Initialize LOGICAL VOLUME REBUILD FILE 
   (( lv = $lv + 1 ))
   recovery_disks=`lspv | grep "$VG_NAME " | awk '{print $1}'`
   ### UNCOMMENT FOR PS NOT TO BE ACTIVATED AND COMMENT LINE -a -s
   # MKLV_CMDS="mkps -s $page_size $VG_NAME '`echo $recovery_disks`'"
   ### UNCOMMENT FOR PS NOT TO BE ACTIVATED AND COMMENT LINE -a -s
   MKLV_CMDS="mkps -a -n -s $page_size $VG_NAME '`echo $recovery_disks`'"
   print "$VG_NAME:$PS_NAME:$MKLV_CMDS:$lv_type" >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
   rm -f $DRRSTDIR/Logical_Volumes/$lvs
 done

 for lvs in `ls *.sh 2>/dev/null`; do
  VG_NAME=`echo "$lvs" | awk -F"." '{print $1}'`
  LV_NAME=`awk ' /^mklv / {print $0}' $VG_NAME.sh | awk ' /-y/ {print $2}' | awk -F"-y" '{print $2}'`

  for i in $LV_NAME; do 
   ### Initialize LOGICAL VOLUME REBUILD FILE 
   lv_type=jfs
   (( lv = $lv + 1 ))
   MKLV_CMDS="`awk ' /-y'$i' / {print $0}' $VG_NAME.sh`"
   MKLV_STRP="`echo "$MKLV_CMDS" | awk ' / -S/ {print $0}'`"
   MKLV_MIRR="`echo "$MKLV_CMDS" | awk ' / -c/ {print $0}'`"
   if [[ -n $MKLV_STRP ]]; then
    if [[ -n $MKLV_MIRR ]]; then 
    print "$VG_NAME:$i:$MKLV_CMDS:$lv_type:STRIPE:MIRROR" >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
    else
     print "$VG_NAME:$i:$MKLV_CMDS:$lv_type:STRIPE:" >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
    fi
   else
    if [[ -n $MKLV_MIRR ]]; then 
     print "$VG_NAME:$i:$MKLV_CMDS:$lv_type::MIRROR" >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
    else
     print "$VG_NAME:$i:$MKLV_CMDS:$lv_type::" >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
    fi
   fi
  done 
 done

 ## STRIPE LV's FIRST
 awk '/:STRIPE:/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS > $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP
 if [[ -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP ]]; then
 awk '! /:STRIPE:/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS > $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP2
  cat $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP > $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
  rm -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP
  if [[ -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP2 ]]; then
   cat $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP2 >> $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
   rm -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP2
  fi
 fi

 if (( $OSL >= 430.0 )); then
  print "\n" | tee -a $logfile
  sep_lin3 | tee -a $logfile
  print "Logical Volume(s) building in Parallel!" | tee -a $logfile
  sep_lin3 | tee -a $logfile

  while (( $lv >= 0 )); do

   if (( `cat $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS 2>/dev/null|awk '{print $0}'|wc -c` <= 1 )); then
     break 
   fi

   for i in `awk -F":" '{print $1}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS`; do
    LV_NAME=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS| awk -F":" '{print $2}'`
    for j in $LV_NAME; do
    if [[ ! -n `ps -aef | grep mklv | egrep "$i" | egrep -v grep` && ! -n `ps -aef | grep tcbck | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -n `ps -aef | grep mkps | egrep "$i"` ]]; then
    if [[ ! -f /etc/security/tcbck.LCK ]]; then
    LV_TYPE=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" ' /:'$j':/ {print $4}'`
    LV_STRP=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" ' /:'$j':/ {print $5}'`
    LV_MIRR=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" ' /:'$j':/ {print $6}'`

    if [[ $LV_TYPE != paging ]]; then
     awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk ' /-y'$j' / {print $0}' | awk -F":" '{print $3}' > $DRRSTDIR/Logical_Volumes/build_lvs.$lv
      chmod 755 $DRRSTDIR/Logical_Volumes/build_lvs.$lv
    else # PAGING SPACE
      awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk ' /:'$j':/ {print $0}' | awk -F":" '{print $3}' > $DRRSTDIR/Logical_Volumes/build_lvs.$lv
     chmod 755 $DRRSTDIR/Logical_Volumes/build_lvs.$lv
    fi

     if [[ -f $DRRSTDIR/Logical_Volumes/$i.Success ]]; then
      if [[ ! -n `awk ' /Re-built: '$j' / {print $0}' $DRRSTDIR/Logical_Volumes/$i.Success` ]]; then
        LV_SETTINGS=`lslv $j 2>/dev/null`
        if [[ -n $LV_SETTINGS ]]; then
         ### ENTRY NOT in $VGNAME.Success
         print "\nFound existing LOGICAL VOLUME: $j" | tee -a $logfile
         print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
         print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
         print "Re-built: $j ">>$DRRSTDIR/Logical_Volumes/$i.Success
         ### END CHECK FOR EXISTING LV's
        else 
         print "\nBuilding: $j"
         if [[ $CMDS0 = YES ]]; then
          cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
          ## REMOVE lsvg -p ENTRIES FOR STRIPE LV
          if [[ -f $DRRSTDIR/Logical_Volumes/$i.stripe ]]; then
           rm -f $DRRSTDIR/Logical_Volumes/$i.stripe
          fi
         fi
        fi

       if [[ $CMDSO != YES ]]; then
        if [[ -n `egrep " -S" $DRRSTDIR/Logical_Volumes/build_lvs.$lv` && -n `egrep " -c " $DRRSTDIR/Logical_Volumes/build_lvs.$lv` ]]; then
         if [[ ! -n $LV_SETTINGS ]]; then
          if [[ -n $LV_STRP ]]; then
           find_stripe_dasd $i $j YES $DRRSTDIR/Logical_Volumes/build_lvs.$lv
          fi
         fi

        else

         ### CHECK FOR EXISTING LV's W/-W/O STRIPPED LOGICAL VOLUME
         if [[ ! -n $LV_SETTINGS ]]; then
          if [[ -n $LV_STRP ]]; then
           find_stripe_dasd $i $j NO $DRRSTDIR/Logical_Volumes/build_lvs.$lv
          else
           if [[ -n $LV_MIRR ]]; then
            find_mirror_dasd $i $j
           fi
           cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
           ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log & 
           sleep 1
           ## REMOVE lsvg -p ENTRIES FOR STRIPE LV
           if [[ -f $DRRSTDIR/Logical_Volumes/$i.stripe ]]; then
            rm -f $DRRSTDIR/Logical_Volumes/$i.stripe
           fi
          fi
         fi
        fi
       else
        print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
        print "$j" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
       fi

      else
       print "Pre-Built: $j"
       print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
      fi  

     else  ### NO *.Success FILE Present

      LV_SETTINGS=`lslv $j 2>/dev/null`
      if [[ -n $LV_SETTINGS ]]; then
       ### ENTRY NOT in $VGNAME.Success
       print "\nFound existing LOGICAL VOLUME: $j" | tee -a $logfile
       print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
       print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
       print "Re-built: $j ">>$DRRSTDIR/Logical_Volumes/$i.Success
       ### END CHECK FOR EXISTING LV's
      else 
       print "\nBuilding: $j"
       if [[ $CMDS0 = YES ]]; then
        cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
        ## REMOVE lsvg -p ENTRIES FOR STRIPE LV
        if [[ -f $DRRSTDIR/Logical_Volumes/$i.stripe ]]; then
         rm -f $DRRSTDIR/Logical_Volumes/$i.stripe
        fi
       fi
      fi

     if [[ $CMDSO != YES ]]; then
      ### CHECK FOR STRIPPED/MIRRORED LOGICAL VOLUMES
      if [[ -n `egrep " -S" $DRRSTDIR/Logical_Volumes/build_lvs.$lv` && -n `egrep " -c " $DRRSTDIR/Logical_Volumes/build_lvs.$lv` ]]; then

       ### CHECK FOR EXISTING LV's
       if [[ ! -n $LV_SETTINGS ]]; then
        if [[ -n $LV_STRP ]]; then
         find_stripe_dasd $i $j YES $DRRSTDIR/Logical_Volumes/build_lvs.$lv
        fi
       fi

      else
       ### REGULAR LOGICAL VOLUMES W/-W/O STRIPPED LOGICAL VOLUME
       ### CHECK FOR EXISTING LV's
       if [[ ! -n $LV_SETTINGS ]]; then
        if [[ -n $LV_STRP ]]; then
         find_stripe_dasd $i $j NO $DRRSTDIR/Logical_Volumes/build_lvs.$lv
        else
           if [[ -n $LV_MIRR ]]; then
            find_mirror_dasd $i $j
           fi
         cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
         ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log & 
         ## REMOVE lsvg -p ENTRIES FOR STRIPE LV
         if [[ -f $DRRSTDIR/Logical_Volumes/$i.stripe ]]; then
          rm -f $DRRSTDIR/Logical_Volumes/$i.stripe
         fi
        fi
       fi
      fi
      sleep 1
     else
      print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
      print "$j" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
     fi
     fi

     awk ' !/:'$j':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS > $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP
     mv $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
     (( lv = $lv - 1 ))
     break 
    fi
   fi
    done
   done
  done
  print ""

  error_control
  print "\nLogical Volume(s) re-build is complete!\n"

 else  ### BUILD SERIALLY

  print "\n" | tee -a $logfile
  sep_lin3 | tee -a $logfile
  print "Logical Volume(s) building Serially!" | tee -a $logfile
  sep_lin3 | tee -a $logfile
  print "" 

  while (( $lv >= 0 )); do

   if (( `cat $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS 2>/dev/null|awk '{print $0}'|wc -c` <= 1 )); then
     break 
   fi

   for i in `awk -F":" '{print $1}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | sort -u`; do
    LV_NAME=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" '{print $2}'`

    for j in $LV_NAME; do
    if [[ ! -n `ps -aef | grep mklv | egrep "$i" | egrep -v grep` && ! -n `ps -aef | grep tcbck | egrep -v grep` && ! -n `ps -aef | grep putlvodm | egrep -v grep` && ! -n `ps -aef | grep mkps | egrep "$i"` ]]; then
    if [[ ! -f /etc/security/tcbck.LCK ]]; then
    LV_TYPE=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" ' /:'$j':/ {print $4}'`
    LV_MIRR=`awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk -F":" ' /:'$j':/ {print $6}'`

    if [[ $LV_TYPE != paging ]]; then
     awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk ' /-y'$j' / {print $0}' | awk -F":" '{print $3}' > $DRRSTDIR/Logical_Volumes/build_lvs.$lv
      chmod 755 $DRRSTDIR/Logical_Volumes/build_lvs.$lv
    else # PAGING SPACE
      awk ' /^'$i':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS | awk ' /:'$j':/ {print $0}' | awk -F":" '{print $3}' > $DRRSTDIR/Logical_Volumes/build_lvs.$lv
     chmod 755 $DRRSTDIR/Logical_Volumes/build_lvs.$lv
    fi

     if [[ -f $DRRSTDIR/Logical_Volumes/$i.Success ]]; then
      if [[ ! -n `awk ' /Re-built: '$j' / {print $0}' $DRRSTDIR/Logical_Volumes/$i.Success` ]]; then
       LV_SETTINGS=`lslv $j 2>/dev/null`
       if [[ -n $LV_SETTINGS ]]; then
        ### ENTRY NOT in $VGNAME.Success
        print "\nFound existing LOGICAL VOLUME: $j" | tee -a $logfile
        print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
        print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
        print "Re-built: $j " >> $DRRSTDIR/Logical_Volumes/$i.Success
        ### END CHECK FOR EXISTING LV's
       else
        print "\nBuilding: $j"
        cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
       fi

       if [[ $CMDSO = NO ]]; then
        if [[ ! -n $LV_SETTINGS ]]; then
         if [[ -n $LV_MIRR ]]; then
          find_mirror_dasd $i $j
         fi
         cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
         ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
         sleep 1
        fi
       else
        print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
        print "$j" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
       fi

      else
       print "Pre-Built: $j"
       print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
      fi  

     else
      LV_SETTINGS=`lslv $j 2>/dev/null`
      if [[ -n $LV_SETTINGS ]]; then
       ### ENTRY NOT in $VGNAME.Success
       print "\nFound existing LOGICAL VOLUME: $j" | tee -a $logfile
       print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
       print "$j " > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
       print "Re-built: $j " >> $DRRSTDIR/Logical_Volumes/$i.Success
       ### END CHECK FOR EXISTING LV's
      else
       print "\nBuilding: $j"
       cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
      fi

     if [[ $CMDSO = NO ]]; then
      if [[ ! -n $LV_SETTINGS ]]; then
      ### ENTRY NOT in $VGNAME.Success
        if [[ -n $LV_MIRR ]]; then
         find_mirror_dasd $i $j
        fi
        cat $DRRSTDIR/Logical_Volumes/build_lvs.$lv | tee -a $logfile 
        ksh $DRRSTDIR/Logical_Volumes/build_lvs.$lv 2>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error 1>$DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log 
        sleep 1
      fi
     else
      print "" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.error
      print "$j" > $DRRSTDIR/Logical_Volumes/$i.$j.$LV_TYPE.log
     fi
     fi

     awk ' !/:'$j':/ {print $0}' $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS > $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP
     mv $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS.TMP $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
     (( lv = $lv - 1 ))
     break 
    fi
   fi
    done
   done
  done
 ### BUILD SERIALLY

 error_control
 print "\nLogical Volume(s) build complete!\n"

 fi

 if [[ -f $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE ]]; then
  sep_lin3 | tee -a $logfile
  print "Building Filesystem(s)!" | tee -a $logfile
  sep_lin3 | tee -a $logfile

  for z in `cat $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE`; do
   ### CHECK FOR SUCCESSFULL BUILD OF LOGICAL VOLUME
   lv_name=`echo "$z" | awk -F":" '{print $2}'` 
   vg_name=`fgrep -l "y$lv_name " *.sh | awk -F"." '{print $1}'`
   i=`echo "$z"|awk -F":" '{print $1}'`

   if [[ -f $DRRSTDIR/Logical_Volumes/$vg_name.Success ]]; then
    if [[ -n `egrep "Re-built: $lv_name " $DRRSTDIR/Logical_Volumes/$vg_name.Success` ]]; then
     if [[ -z  `egrep "Re-built FILESYSTEM: $i " $DRRSTDIR/Logical_Volumes/$vg_name.Success` ]]; then 
      ### CHECK FOR EXISTING FILESYSTEMS
      FS_SETTINGS=`lsfs -q $i 2>/dev/null`
      if [[ -n `echo "$FS_SETTINGS" | egrep "lv size|fs size"` ]]; then
       print "Found existing FILESYSTEM: $i" | tee -a $logfile
       print "Re-built FILESYSTEM: $i ">>$DRRSTDIR/Logical_Volumes/$vg_name.Success
       rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
       rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
      else

       print "\nBuilding filesystem: $i"
       filesystem=`egrep "d$lv_name " $vg_name.commands | egrep "$i " | awk ' /^crfs/ {print $0}'`
       print "$filesystem" | tee -a $logfile
 
      if [[ $CMDSO != YES ]]; then
       chmod 755 /$DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
       $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs 2>/$DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
       if (( $? != 0 )); then
        print "Filesystem $i failed to build!" | tee -a $logfile
        print "Filesystems ERROR!  $i " >> $DRRSTDIR/REBUILD.ERRORS
        cat $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error >> $DRRSTDIR/REBUILD.ERRORS
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
       else
        print "Re-built FILESYSTEM: $i " >> $DRRSTDIR/Logical_Volumes/$vg_name.Success
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
       fi
       else
        print "Re-built FILESYSTEM: $i"
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
        rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
       fi
      fi

     else
      print "Pre-Built Filesystem: $i" | tee -a $logfile  
      rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.fs
      rm -f $DRRSTDIR/Logical_Volumes/$vg_name.$lv_name.error
     fi

    else
     print "\a\nError cannot build filesystem:\t$i " | tee -a $logfile
     print "Failed to build Logical Volume: $lv_name \n" | tee -a $logfile
     print "Error!  Failed to build $i.  LV $lv_name has not been created first " >> $DRRSTDIR/REBUILD.ERRORS
    fi

    if [[ -n  `egrep "Re-built FILESYSTEM: $i " $DRRSTDIR/Logical_Volumes/$vg_name.Success` ]]; then 
     ### MAKE DIRECTORIES
     if [[ ! -d $i ]]; then
      if [[ $CMDSO != YES ]]; then
      mkdir -p $i
      fi
     fi

     ### MOUNT THE FILESYSTEMS
     if [[ $CMDSO != YES ]]; then
     mount $i 2>/dev/null 1>>$logfile
     print "mount $i " >> $logfile

     ### CHANGE OWNER SHIP ACL
     ownership=`awk ' /^chown / {print $0}' $vg_name.commands | egrep " $i" | awk '{print $2}'`
     print "chown $ownership $i" >> $logfile
     chown $ownership $i 2>/dev/null 1>>$logfile
     print "" >> $logfile
     fi

    fi
 
   fi
  done
  print "\nFilesystem(s) re-build complete!\n"
 fi

 ### CHANGE OWNER SHIP ACL FOR RAW LV's
 if [[ $CMDSO != YES ]]; then
  cd $DRRSTDIR/Logical_Volumes
  ls *.Success 2>/dev/null 1>/dev/null
  if (( $? == 0 )); then
  for i in `ls *.Success`; do
   vg_name=`echo "$i" | awk -F"." '{print $1}'`
   awk ' /^chown / {print $0}' $vg_name.commands>$DRRSTDIR/Logical_Volumes/CHACL
   if [[ -f $DRRSTDIR/Logical_Volumes/CHACL ]]; then
    chmod 755 $DRRSTDIR/Logical_Volumes/CHACL
    print "CHANGING OWNERSHIP PERMISSIONS FOR VG: $vg_name" >> $logfile
    $DRRSTDIR/Logical_Volumes/CHACL 2>/dev/null 1>/dev/null
    rm -f $DRRSTDIR/Logical_Volumes/CHACL
   fi
  done
  fi
 fi
 
 if [[ $CMDSO != NO ]]; then
  rm -rf $DRRSTDIR/Logical_Volumes/*.Success
 fi

 rm -f $DRRSTDIR/Logical_Volumes/FILESYSTEMS.$RESTORE_DATE
 rm -f $DRRSTDIR/Logical_Volumes/BUILD.LOGICALS
 rm -f $DRRSTDIR/Logical_Volumes/MIRRORED.VGS
 rm -f $DRRSTDIR/Logical_Volumes/build_lvs.*
 rm -f $DRRSTDIR/Logical_Volumes/*.stripe
 rm -f $DRRSTDIR/Logical_Volumes/*.sh
 rm -f $DRRSTDIR/VG_REBUILD.*
 rm -f $DRRSTDIR/VG_LVBUILD.*
}

####################################################################
#### Returns:  $PAGE
####################################################################
find_page() 
{
 PAGE=""

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/PAGING_SPACES.* $DRRSTDIR/Logical_Volumes/*.paging_space $DRRSTDIR/*.paging; exit' 1 2 15

 PAGE=`awk '/^PAGING_INFO:/ {print $0}' $DRDIR/$RBLD |sed -es!"PAGING_INFO:"!" "!g | sed -es!";:"!" "!g|sed -es!";"!""!g`
 #  echo "PAGE: $PAGE"

 if [[ -n $PAGE ]]; then 
 print "\n" >> $logfile
 clear
 print_ver
 print "Verifying Non-ROOTVG Paging Space(s) are needed for rebuild!\n"| tee -a $logfile
  
  if [[ $SNAPSHOT = YES ]]; then
   sep_lin3 | tee -a $logfile
   pr -5 -t -w78 -l1 - << END | tee -a $logfile
Paging Space 
  VG Name
Auto On 
Mirror
Size(GB)
END
   sep_lin3 | tee -a $logfile
  fi

  for i in $PAGE; do
   page_vgne=`echo "$i" | awk -F":" '{print $3}'`
   if [[ $page_vgne != rootvg ]]; then
    page_name=`echo "$i" | awk -F":" '{print $1}'`
    auto_actv=`echo "$i" | awk -F":" '{print $5}'`
    mirror_pg=`echo "$i" | awk -F":" '{print $6}'`
    size_page=`echo "$i" | awk -F":" '{print $4}'`
    if [[ -n $mirror_pg ]]; then
     mirror_pg="yes"
    else
     mirror_pg="no"
    fi
    if [[ -n $size_page ]]; then
     size_page_tmp=`echo "$size_page" | sed -es!"MB"!""!g`
     size_page=`echo "scale=2; $size_page_tmp / 1000" | bc`
    fi
    if [[ $SNAPSHOT = YES ]]; then
     pr -5 -t -w78 -l1 - << END | tee -a $logfile
$page_name
  $page_vgne
 $auto_actv
 $mirror_pg
$size_page
END
    fi
   fi 
  done

  print "\nActual Paging Space(s) found: \n" | tee -a $logfile
  lsps -a | egrep -v "rootvg " | tee -a $logfile
  print "\n" | tee -a $logfile
 fi
}

####################################################################
#### Returns:  $PAGE, $JFSLOG
#### Mirror all Paging Spaces and JFS Logs
####################################################################
mirror_all() 
{
 PAGE=""
 JFSLOG=""

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/PAGING_SPACES.* $DRRSTDIR/Logical_Volumes/*.paging_space $DRRSTDIR/*.paging; exit' 1 2 15

 cd $DRRSTDIR/Logical_Volumes
 JFSLOG=`fgrep -l jfslog *.commands`

 PAGE=`awk '/^PAGING_INFO:/ {print $0}' $DRDIR/$RBLD |sed -es!"PAGING_INFO:"!" "!g | sed -es!";:"!" "!g|sed -es!";"!""!g`
 #  echo "PAGE: $PAGE"

 if [[ -n $PAGE || -n JFSLOG ]]; then 
  print "\n" >> $logfile
  clear
  print_ver
  sep_line >> $logfile
  print "Verifying if Mirroring is needed for Non-ROOTVG Volume Groups!\n"|tee -a $logfile

  if [[ $SNAPSHOT = YES ]]; then
   find_page snapshot
   print ""
  fi

  if [[ ! -d $DRRSTDIR/Logical_Volumes ]]; then
   mkdir -p $DRRSTDIR/Logical_Volumes
  fi
  cd $DRRSTDIR/Logical_Volumes

  ### PAGING SPACE BUILDS
  if [[ -f $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE || -n $JFSLOG ]]; then
   for i in `ls *.paging 2>/dev/null`; do
    lv_vgnm=`echo "$i" | awk -F"." '{print $1}'`
    page_space=`echo "$i" | awk -F"." '{print $2}'`
    real_page=`cat $i | awk -F":" '{print $3}'`
    page_size=`egrep "^$lv_vgnm" $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE | egrep ":$page_space:" | awk -F":" '{print $4}'`

    page_mirr=`cat $i  | awk -F":" '{print $2}'`
    recovery_disks=`lspv | grep "$lv_vgnm " | awk '{print $1}'`
    ### CHECK FOR PAGING SPACE MIRROR
    if [[ $page_mirr = MIRROR ]]; then
     print "Mirror Page Space:  $real_page" | tee -a $logfile
     if [[ ! -n `egrep ": $page_space :Mirror" $lv_vgnm.Success 2>/dev/null` ]]; then
     print "mklvcopy $real_page 2 '`echo $recovery_disks`'\n" | tee -a $logfile
     if [[ $CMDSO != YES ]]; then
     mklvcopy $real_page 2 $recovery_disks
     if (( $? != 0 )); then
      print "Mirror Failed for Paging Space: $real_page!" | tee -a $DRRSTDIR/REBUILD.ERRORS
     else
      rm -f $i
      sed -es!": $page_space "!": $page_space :Mirror"!g $lv_vgnm.Success > $lv_vgnm.Success.tmp
      mv $lv_vgnm.Success.tmp $lv_vgnm.Success
     fi
     fi
     fi
    fi
   done
   
   ### CHECK JFSLOG MIRROR
   for i in $JFSLOG; do
    lv_vgnm=`echo "$i" | awk -F"." '{print $1}'`
    lv_log=`lsvg -l $lv_vgnm | egrep "jfslog" | awk '{print $1}'`
    if [[ -n $lv_log ]]; then
    print "Mirror jfslog for Volume Group: $lv_vgnm" | tee -a $logfile
    if [[ ! -n `egrep ": $lv_log :Mirror" $lv_vgnm.Success 2>/dev/null` ]]; then
     recovery_disks=`lspv | grep "$lv_vgnm " | awk '{print $1}'`
     print "mklvcopy $lv_log 2 '`echo $recovery_disks`'\n" | tee -a $logfile
     mklvcopy $lv_log 2 $recovery_disks
     if (( $? != 0 )); then
      print "Mirror Failed for jfslog: $lv_log!" | tee -a $DRRSTDIR/REBUILD.ERRORS
     else
      print "Re-built: $log_lv :Mirror" >> $lv_vgnm.Success
     fi
    fi
    fi
   done
  
   if [[ -n `fgrep -l ":Mirror" *.Success 2>/dev/null` ]]; then 
   print ""
   sep_lin3 | tee -a $logfile
   print "Syncing Logical Volume(s) for Volume Group(s):" | tee -a $logfile
   sep_lin3 | tee -a $logfile
   for i in `fgrep -l ":Mirror" *.Success 2>/dev/null`; do
    lv_vgnm=`echo "$i" | awk -F"." '{print $1}'`
    print "$lv_vgnm:" | tee -a $logfile
    print "syncvg -v $lv_vgnm\n" | tee -a $logfile
    if [[ -n `lsvg -l $lv_vgnm 2>/dev/null | egrep "stale"` && ! -n `ps -aef | egrep syncvg | egrep "$lv_vgnm "` ]]; then
     syncvg -v $lv_vgnm 2>/dev/null &
    fi
   done
   print "\nPlease note!  Once the 'syncvg' has completed for each VG. "
   print "Manually verify that the logical volume copies"
   print "have been synced, issue: 'lsvg -l <Volume_Group_Name>'"
   print "and look for 'LV STATE', or run 'dr_restore.sh -v'.\n"
   sleep 4
   fi
  fi

  rm -f $DRRSTDIR/PAGING_SPACES.$RESTORE_DATE

 fi
}

####################################################################
### VERIFY MOUNTED NFS FILESYSTEMS, CHECK MOUNT AND PERMISSIONS 
### USES find_nfs() FOR INPUT AND 
### CHECKS W/I /ETC/FILESYSTEMS FOR NFS FILESYSTEMS
####################################################################
find_nfs()
{

 trap 'rm -f $DRRSTDIR/NFS_SETTINGS.*; break' 1 2 15

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 EXPORTEDFS=""

 lsfs -q -v nfs 2>/dev/null | awk '
BEGIN {
  numfs   = 1
  size  = 0
  name    = 1
  node    = 2
  mtpt    = 3
  nfs     = 4
  optn    = 5

 }
/Accounting/ { next }
{
  fs[numfs,name]  = $1
  fs[numfs,node]  = $2
  fs[numfs,mtpt]  = $3
  fs[numfs,nfs]   = $4
  fs[numfs,optn]  = $6
  size            = $5
  numfs++
}

END {
  printf("---------------------------------------------------------------------------\n")
  printf("Name\t\t      Nodename     Mount Pt\t\t VFS   Options\n")
  printf("---------------------------------------------------------------------------\n")
  for (i = 1; i < numfs; i++) {
    printf("%-21s %-12s %-21s %-5s %-10s",fs[i,name],fs[i,node],fs[i,mtpt],fs[i,nfs],fs[i,optn])
    printf("\n")
  }
}' >$DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE


 if [[ -f $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE ]]; then 
  print "\n" >> $logfile
  clear
  print_ver
  sep_line >> $logfile
  print "Verifying NFS settings for 'REBUILD'.\n"|tee -a $logfile

  if [[ $SNAPSHOT = YES ]]; then
   cat $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE | tee -a $logfile
   print "\n" >> $logfile 
  else
   cat $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE >> $logfile
   print "\n" >> $logfile 
  fi

  print "\nWill try to mount remote filesystems!  If command hangs, press" 
  print "<CNT-C> and break from the NFS rebuild routines!  Note the "
  print "'dr_restore' script will continue to the next rebuild routine.\n" 
  sleep 4

  if [[ -f $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE ]]; then
  sort -k2 -o $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE 
  
  for i in `awk ' !/'^Name'|'^--'/ {print $3}' $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE`; do
   node_hostname=`egrep " $i " $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE | awk '{print $2}'`
   remote_mountpt=`egrep " $i " $DRRSTDIR/NFS_SETTINGS.$RESTORE_DATE | awk '{print $1}'`
   print "Mounting: $i" | tee -a $logfile
   if [[ $CMDSO != YES ]]; then
   if [[ ! -d $i ]]; then
    print "mkdir -p $i" | tee -a $logfile
    mkdir -p $i 2>>$DRRSTDIR/REBUILD.ERRORS 1>/dev/null
    if [ $? != 0 ]; then
     print "Error creating directory: $i" | tee -a $logfile
    fi
   fi
 
   ### FIRST TRY TO PING REMOTE HOST 
   ping -c 1 $node_hostname 10 2>>$DRRSTDIR/REBUILD.ERRORS 1>/dev/null
   if [ $? != 0 ]; then 
    print "ERROR -- Unreachable host: $node_hostname\n" | tee -a $logfile
    sleep 1
   else
    ### SECOND LOOK AT REMOTE HOST FOR EXPORTED FS
    EXPORTEDFS=`showmount -e $node_hostname 2>>$DRRSTDIR/REBUILD.ERRORS | egrep "$remote_mountpt "`
    if [[ -n $EXPORTEDFS ]]; then
     mount $i 2>>$DRRSTDIR/REBUILD.ERRORS 
     if [ $? != 0 ]; then 
      print "ERROR -- Failed to mount: $i" | tee -a $logfile 
      print "Check rebuild error file $DRRSTDIR/REBUILD.ERRORS\n" | tee -a $logfile 
      sleep 2
     else
      print "O.K." | tee -a $logfile
     fi
    else
     print "ERROR -- Filesystem: $remote_mountpt not exported on node: $node_hostname\n" | tee -a $logfile 
     sleep 2
    fi
   fi
   fi
    
  done
  fi
 fi


}

####################################################################
#### Find TCP 'no' Settings and Verify against rebuild system
####################################################################
find_net()
{
 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 trap 'rm -f $DRRSTDIR/NETWORK_SETTINGS.*; exit' 1 2 15

 NET=`cat $DRDIR/$RBLD | awk '/^NO_INFO/ {print $0}'|sed -es!"NO_INFO="!""!g`
 #print "NET: $NET"

 if [[ -n $NET ]]; then 
 print "\n" >> $logfile
 clear
 print_ver
 sep_line >> $logfile
 print "Verifying TCP/IP 'no' settings for 'REBUILD'.\n"|tee -a $logfile

 print "Please wait!"
 for i in $NET; do
  waiter2
  tcp_arg=`echo "$i" | awk -F'=' '{print $1}'`
  tcp_set=`echo "$i" | awk -F'=' '{print $2}'`

  if [[ -n `echo "$tcp_set" | egrep "[0-9]"` ]]; then 
   tcp_tmp=`no -o $tcp_arg 2>/dev/null | awk -F'=' '{print $2}'`
   tcp_tmp=`echo $tcp_tmp`

   if [[ -n $tcp_tmp ]]; then
   if (( $tcp_tmp != $tcp_set )); then
    print "no -o $tcp_arg=$tcp_set" >> $logfile
    if [[ $CMDSO != YES ]]; then
     no -o $tcp_arg=$tcp_set  
    fi
    if [[ ! -n `egrep "$tcp_arg=" $DRRSTDIR/NETWORK_SETTINGS.$RESTORE_DATE 2>/dev/null` ]];
     then
     print "no -o $tcp_arg=$tcp_set" >> $DRRSTDIR/NETWORK_SETTINGS.$RESTORE_DATE
     print "no -o $tcp_arg=$tcp_set" >> /etc/rc.net 
    fi
   fi
   fi
  fi
 done
 print ""
 if [[ -f $DRRSTDIR/NETWORK_SETTINGS.$RESTORE_DATE ]]; then
  print ""
  cat $DRRSTDIR/NETWORK_SETTINGS.$RESTORE_DATE
  print ""
 fi
 fi

}

####################################################################
### VERIFY SYSTEM RESTORE 
####################################################################
verify_system()
{
 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 clear
 print_ver
 
 if [[ $SNAPSHOT = YES ]]; then
  print "Would you like to verify the system restore?\n"
  print "Enter Y/N \c"
   while read input; do
     case $input in
      Y|y) sep_line >> $logfile
          print "For system verification look in the 'Verify.${RESTORE_DATE}.log'\n" >> $logfile
         if [[ $SNAPSHOT = YES ]]; then
          verify_all snapshot 1
         else
          verify_all 1 1
         fi 
         exit 1;;
      N|n) print "\nExiting DR Restore run!\n"
         exit 1;;
      *) ;;
     esac
     printf "Enter Y/N  \a"
   done
  else
   verify_all 1 1
   exit 1
  fi
 }

####################################################################
### VERIFY NAME AND SIZE OF REBUILT VOLUMES GROUPS
####################################################################
found_vg()
{
 ### USES find_vg() OUTPUT TO COMPARE AGAINST
 max_k=$k
 k=1
 VG_NAME=""
 VG_SIZE=""
 FD_VG=0

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 print "\n" | tee -a $logfile 
 sep_lin3 | tee -a $logfile
 print "Rebuilt Volume Groups" | tee -a $logfile
 sep_lin3 | tee -a $logfile
 print "TOTAL NUMBER OF VGs NEEDED: $max_k\n"
 MX_VG=$max_k
 while (( $k <= $max_k )); do
  if (( `echo ${vg_array[$k]}|awk '{print $0}'|wc -c` > 1 )); then
   VG_NAME=`echo ${vg_array[$k]}|awk -F":" '{print $1}'`
   VG_SIZE=`echo ${vg_array[$k]}|awk -F":" '{print $3}'`
  
   if [[ -n `lspv | grep -w "$VG_NAME"` ]]; then
    ACTUAL_SIZE=`lsvg $VG_NAME | egrep "TOTAL PPs: " | awk -F":" '{print $3}' | awk '{print $2}'|sed -es!"("!""!g`
    if (( $ACTUAL_SIZE >= $VG_SIZE )); then
     (( FD_VG = $FD_VG + 1 ))
     printf "%-5s%-16.15s%-4s%-3s\n" $k. $VG_NAME -- O.K.  |tee -a $logfile
    else
     (( FD_VG = $FD_VG + 1 ))
     printf "%-5s%-16.15s%-4s%-6s\n" $k. $VG_NAME -- WARNING  |tee -a $logfile
    fi
   else
    printf "%-5s%-16.15s%-4s%-6s%-4s%-4s%-7s\n" $k. $VG_NAME -- ERROR -- NOT REBUILT |tee -a $logfile
   fi
  fi
  (( k = $k + 1 ))
 done

 (( k = $k - 1 ))
 print "\nTOTAL NUMBER OF VGs FOUND: $FD_VG" | tee -a $logfile

}

####################################################################
### VERIFY NAME AND SIZE OF REBUILT LOGICAL VOLUMES 
### USES build_logical_volumes() OUTPUT TO COMPARE AGAINST
####################################################################
found_lv()
{

 trap 'break' 1 2 15

 LVSIZE()
 {

 trap 'break' 1 2 15

 max_k=$k
 k=0
 LV_COUNT=0
 lv_type=$1
 while (( $k <= $max_k )); do
  if (( `echo ${lv_array[$k]}|awk '{print $0}'|wc -c` > 1 )); then
   VG_NAME=`echo ${lv_array[$k]}|awk -F":" '{print $1}'`
   LV_NAME=`echo ${lv_array[$k]}|awk -F":" '{print $3}'`
   LV_TYPE=`echo ${lv_array[$k]}|awk -F":" '{print $4}'`

   ### CHECK FOR RAW TYPES NOT LABELED AS 'N/A'
   if [[ $LV_TYPE != paging && $LV_TYPE != jfs && $LV_TYPE != jfslog && $LV_TYPE != jfs2 && $LV_TYPE != jfs2log ]]; then
    LV_TYPE="other"
   fi

   if [[ $LV_TYPE = $lv_type ]]; then
   LV_PPSIZE=`echo ${lv_array[$k]}|awk -F":" '{print $2}'`
   LV_LPNUMB=`echo ${lv_array[$k]}|awk -F":" '{print $5}'`
   LV_PPNUMB=`echo ${lv_array[$k]}|awk -F":" '{print $6}'`
   (( LV_SIZE = $LV_PPSIZE * $LV_LPNUMB ))
   (( LV_COUNT = $LV_COUNT + 1 ))

   ###CHECK FOR PAGING
   if [[ $LV_TYPE = paging ]]; then 
    ### CHECK VG_NAME, LV_NAME NOT NECESSARILY THE SAME
    LV_PAGE=`lsvg -l $VG_NAME|egrep -v "LV NAME |$VG_NAME:"|egrep "paging "`
    if (( `echo "$LV_PAGE" | wc -l` > 1 )); then
     print "More than one Paging Space in VG: $VG_NAME"|tee -a $logfile
     for i in `echo "$LV_PAGE" | awk '{print $1}'| sort -u`;do
      ACTUAL_SIZE=`lslv $i | egrep "PP SIZE: |PPs: "`
      if [[ -n $ACTUAL_SIZE ]]; then
       ACTUAL_LV_PPSIZE=`echo "$ACTUAL_SIZE" |egrep "PP SIZE: "| awk -F":" '{print $3}'|awk '{print $1}'` 
       ACTUAL_LV_LPNUMB=`echo "$ACTUAL_SIZE" |egrep "^LPs: "| awk -F":" '{print $2}'|awk '{print $1}'` 
       (( ACTUAL_LV_SIZE = $ACTUAL_LV_PPSIZE * $ACTUAL_LV_LPNUMB ))
       if (( $ACTUAL_LV_SIZE == $LV_SIZE )); then
        (( FD_PAGING = $FD_PAGING + 1 ))
        LV_NAME=`echo "$i" | awk '{print $1}'`
        break
       fi
      fi
     done
      if [[ ! -n $LV_NAME ]]; then
       LV_NAME=$i
      fi
    else
     LV_NAME=`echo "$LV_PAGE" | awk '{print $1}'`
     ACTUAL_SIZE=`lslv $LV_NAME | egrep "PP SIZE: |PPs: "`
    fi
   fi

   ### CHECK FOR JFSLOG MIRROR
   if [[ $LV_TYPE = jfslog ]]; then 
    LV_NAME=`lsvg -l $VG_NAME | egrep "jfslog " | awk '{print $1}'`
    if [[ ! -n $LV_NAME ]]; then
     ACTUAL_SIZE=""
    else 
     ACTUAL_SIZE=`lslv $LV_NAME | egrep "PP SIZE: |PPs: "`
     ACTUAL_LV_PPSIZE=`echo "$ACTUAL_SIZE" |egrep "PP SIZE: "| awk -F":" '{print $3}'|awk '{print $1}'` 
     ACTUAL_LV_LPNUMB=`echo "$ACTUAL_SIZE" |egrep "^LPs: "| awk -F":" '{print $2}'|awk '{print $1}'` 
     LV_PPSIZE=$ACTUAL_LV_SIZE
     LV_LPNUMB=$ACTUAL_LV_LPNUMB
    fi
   fi  ### JFSLOG 

   if [[ $LV_TYPE = jfs2log ]]; then 
    LV_NAME=`lsvg -l $VG_NAME | egrep "jfs2log " | awk '{print $1}'`
    if [[ ! -n $LV_NAME ]]; then
     ACTUAL_SIZE=""
    else 
     ACTUAL_SIZE=`lslv $LV_NAME | egrep "PP SIZE: |PPs: "`
     ACTUAL_LV_PPSIZE=`echo "$ACTUAL_SIZE" |egrep "PP SIZE: "| awk -F":" '{print $3}'|awk '{print $1}'` 
     ACTUAL_LV_LPNUMB=`echo "$ACTUAL_SIZE" |egrep "^LPs: "| awk -F":" '{print $2}'|awk '{print $1}'` 
     LV_PPSIZE=$ACTUAL_LV_SIZE
     LV_LPNUMB=$ACTUAL_LV_LPNUMB
    fi
   fi  ### JFS2LOG 

   if [[ $LV_TYPE = jfs ]]; then 
    ACTUAL_SIZE=`lslv $LV_NAME 2>/dev/null | egrep "PP SIZE: |PPs: "`
    if [ $? != 0 ]; then
     ACTUAL_SIZE="MAX LPs:  5000   PP SIZE:  0 megabyte(s) 
LPs:   0   PPs:   0"
     ACTUAL_SIZE=""
    fi
   fi

   if [[ $LV_TYPE = jfs2 ]]; then 
    ACTUAL_SIZE=`lslv $LV_NAME 2>/dev/null | egrep "PP SIZE: |PPs: "`
    if [ $? != 0 ]; then
     ACTUAL_SIZE="MAX LPs:  5000   PP SIZE:  0 megabyte(s) 
LPs:   0   PPs:   0"
     ACTUAL_SIZE=""
    fi
   fi

   if [[ $LV_TYPE = other ]]; then 
    ACTUAL_SIZE=`lslv $LV_NAME 2>/dev/null | egrep "PP SIZE: |PPs: "`
    if [ $? != 0 ]; then
     ACTUAL_SIZE="MAX LPs:  5000   PP SIZE:  0 megabyte(s) 
LPs:   0   PPs:   0"
     ACTUAL_SIZE=""
    fi
   fi

   if [[ -n $ACTUAL_SIZE ]]; then
    ACTUAL_LV_PPSIZE=`echo "$ACTUAL_SIZE" |egrep "PP SIZE: "| awk -F":" '{print $3}'|awk '{print $1}'` 
    ACTUAL_LV_LPNUMB=`echo "$ACTUAL_SIZE" |egrep "^LPs: "| awk -F":" '{print $2}'|awk '{print $1}'` 
    ACTUAL_PP_PPNUMB=`echo "$ACTUAL_SIZE" |egrep "^LPs: "| awk -F":" '{print $3}'` 
    (( ACTUAL_LV_SIZE = $ACTUAL_LV_PPSIZE * $ACTUAL_LV_LPNUMB ))

    if (( $LV_PPNUMB > $LV_LPNUMB )); then
     ### MIRRORED
     if (( $ACTUAL_LV_SIZE >= $LV_SIZE && $ACTUAL_LV_LPNUMB < $ACTUAL_PP_PPNUMB )); then
      printf "%-5s%-16.15s%-4s%-6s%-4s%-9s\n" $LV_COUNT. $LV_NAME -- O.K. -- MIRRORED  |tee -a $logfile
      (( FD_JFS = $FD_JFS + 1 ))
     else
      if (( $ACTUAL_LV_SIZE >= $LV_SIZE )); then
       printf "%-5s%-16.15s%-3s%-8s%-3s%-4s%8s\n" $LV_COUNT. $LV_NAME -- WARNING -- NOT MIRRORED  |tee -a $logfile
      (( FD_JFS = $FD_JFS + 1 ))
      else
       printf "%-5s%-16.15s%-3s%-8s%-3s%-4s%8s\n" $LV_COUNT. $LV_NAME -- WARNING -- WARNING! |tee -a $logfile
       print "\n\tACTUAL SIZE: $ACTUAL_LV_SIZE -- NEEDED SIZE: $LV_SIZE\n"|tee -a $logfile
      (( FD_JFS = $FD_JFS + 1 ))
      fi
     fi

    else  ### NOT MIRRORED

     if (( $ACTUAL_LV_SIZE >= $LV_SIZE )); then
      printf "%-5s%-16.15s%-4s%-3s\n" $LV_COUNT. $LV_NAME -- O.K.  |tee -a $logfile
      (( FD_JFS = $FD_JFS + 1 ))
     else
       printf "%-5s%-16.15s%-3s%-8s%-3s%-4s%8s\n" $LV_COUNT. $LV_NAME -- WARNING -- WARNING! |tee -a $logfile
       print "\n\tACTUAL SIZE: $ACTUAL_LV_SIZE -- NEEDED SIZE: $LV_SIZE\n"|tee -a $logfile
       (( FD_JFS = $FD_JFS + 1 ))
     fi
    fi

   else
     printf "%-5s%-16.15s%-4s%-7s%-4s%-4s%-7s\n" $LV_COUNT. $LV_NAME -- ERROR -- NOT REBUILT |tee -a $logfile

   fi
   fi
  fi
  (( k = $k + 1 ))
 done
 }

 max_k=$k
 k=0
 LV_JFS=0
 LV_JFS2=0
 LV_JFSLOG=0
 LV_JFS2LOG=0
 LV_PAGING=0
 LV_FILES=0
 LV_OTHER=0
 FD_JFS=0
 FD_PAGING=0
 LV_TOTAL=0
 print "\nTOTAL NUMBER OF LVs NEEDED: $max_k " | tee -a $logfile
 MX_LV=$max_k
 print ""

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 # lv_array[$k]="$lv_vgnm:$lv_ppsz:$lv_name:$lv_type:$lv_lpnb:$lv_lptl:$lv_disk:$lv_mntp:$gb_tot_size"

 ### JFS/JFSLOG/JFS2/JFS2LOG/PAGING/OTHER LOGICAL VOLUMES
 while (( $k <= $max_k )); do
  if (( `echo ${lv_array[$k]}|awk '{print $0}'|wc -c` > 1 )); then
   LV_TYPE=`echo ${lv_array[$k]}|awk -F":" '{print $4}'`
   LV_MTPT=`echo ${lv_array[$k]}|awk -F":" '{print $8}'`

   if [[ $LV_TYPE = jfs ]]; then
    (( LV_JFS = $LV_JFS + 1 ))
   fi

   if [[ $LV_TYPE = jfs2 ]]; then
    (( LV_JFS2 = $LV_JFS2 + 1 ))
   fi

   if [[ $LV_TYPE = paging ]]; then
    (( LV_PAGING = $LV_PAGING + 1 ))
   fi

   if [[ $LV_TYPE = jfslog ]]; then
    (( LV_JFSLOG = $LV_JFSLOG + 1 ))
   fi

   if [[ $LV_TYPE = jfs2log ]]; then
    (( LV_JFS2LOG = $LV_JFS2LOG + 1 ))
   fi

   if [[ $LV_MTPT != "N/A" ]]; then
    (( LV_FILES = $LV_FILES + 1 ))
   fi

   if [[ $LV_TYPE != jfslog && $LV_TYPE != jfs && $LV_TYPE != paging && $LV_TYPE != jfs2 && $LV_TYPE != jfs2log ]]; then
    (( LV_OTHER = $LV_OTHER + 1 ))
   fi

  fi
  (( k = $k + 1 ))
 done

 sep_lin3 | tee -a $logfile
 print "TOTAL NUMBER OF LVs with LV TYPE 'jfs':  $LV_JFS" | tee -a $logfile
 sep_lin3 | tee -a $logfile
 LVSIZE jfs 

 if (( $LV_JFS2 > 0 )); then
  sep_lin3 | tee -a $logfile
  print "TOTAL NUMBER OF LVs with LV TYPE 'jfs2':  $LV_JFS2" | tee -a $logfile
  sep_lin3 | tee -a $logfile
  LVSIZE jfs2 
 fi

 if (( $LV_OTHER > 0 )); then
  sep_lin3 | tee -a $logfile
  print "TOTAL NUMBER OF LVs with LV TYPE 'other':  $LV_OTHER" | tee -a $logfile
  sep_lin3 | tee -a $logfile
  LVSIZE other 
 fi

 ### PAGING LOGICAL VOLUMES
 sep_lin3 | tee -a $logfile
 print "TOTAL NUMBER OF LVs with LV TYPE 'paging':  $LV_PAGING"|tee -a $logfile
 sep_lin3 | tee -a $logfile
 LVSIZE paging 

 ### JFSLOG LOGICAL VOLUMES
 sep_lin3 | tee -a $logfile
 print "TOTAL NUMBER OF LVs with LV TYPE 'jfslog':  $LV_JFSLOG"|tee -a $logfile
 sep_lin3 | tee -a $logfile
 LVSIZE jfslog 

 if (( $LV_JFS2LOG > 0 )); then
  sep_lin3 | tee -a $logfile
  print "TOTAL NUMBER OF LVs with LV TYPE 'jfs2log':  $LV_JFS2LOG"|tee -a $logfile
  sep_lin3 | tee -a $logfile
  LVSIZE jfs2log 
 fi
 
 (( LV_TOTAL = $FD_JFS + $FD_PAGING ))

 print "\nTOTAL NUMBER OF LVs FOUND: $LV_TOTAL\n"|tee -a $logfile

 ### VERIFY REBUILT FILESYSTEMS, CHECK MOUNT AND PERMISSIONS 
 ### JFS FILESYSTEMS 
 if (( $LV_FILES > 1 )); then
 sep_lin3 | tee -a $logfile
 print "TOTAL NUMBER OF FILESYSTEMS NEEDED: $LV_FILES" | tee -a $logfile
 sep_lin3 | tee -a $logfile

 printf "%-4s%-16.15s%-14s%-8s%-10s%-9s%-13s\n" \# Filesystem 1024-blocks Used Available Capacity Mounted_on | tee -a $logfile
 max_k=$k
 k=0
 LV_COUNT=0
 FS_FOUND=0
 lv_type=$1
 while (( $k <= $max_k )); do
  if (( `echo ${lv_array[$k]}|awk '{print $0}'|wc -c` > 1 )); then
   LV_MTPT=`echo ${lv_array[$k]}|awk -F":" '{print $8}'`
   if [[ $LV_MTPT != "N/A" ]]; then
   LV_NAME=`echo ${lv_array[$k]}|awk -F":" '{print $3}'`
   DFOUT=`df -k -P $LV_MTPT 2>/dev/null | egrep -v "^Filesystem"`
   (( LV_COUNT = $LV_COUNT + 1 ))
   if [[ $? = 0 ]]; then
    ### CHECK LV_NAME AGAINST WHAT DF RETURNED    
    if [[ $LV_NAME = `echo "$DFOUT" | awk -F"/" '{print $3}'|awk '{print $1}'` ]]; then
     (( FS_FOUND = $FS_FOUND + 1 ))
     printf "%-4s%s\n" "$LV_COUNT". "$DFOUT" | tee -a $logfile
    else
     printf "%-4s%-20s%-4s%-9s%-7s%-7s%-4s%-4s%-7s\n" $LV_COUNT. $LV_MTPT -- ERROR -- ERROR -- NOT MOUNTED | tee -a $logfile

    fi  ### CHECK LV_NAME AGAINST WHAT DF RETURNED    

   else
    printf "%-4s%-20s%-4s%-9s%-7s%-7s%-4s%-4s%-7s\n" $LV_COUNT. $LV_MTPT -- ERROR -- ERROR -- NOT MOUNTED | tee -a $logfile
   fi
   fi
  fi
  (( k = $k + 1 ))
 done

 fi

 print "\nTOTAL NUMBER OF FILESYSTEMS FOUND: $FS_FOUND\n" |tee -a $logfile

 print "\n\n\t\t\tSUMMARY" | tee -a $logfile
 sep_lin3 | tee -a $logfile
 printf "%-26s%2s%8.7s" "TOTAL NUMBER OF VGs NEEDED" : "$MX_VG"| tee -a $logfile
 print "" | tee -a $logfile
 printf "%-26s%2s%8.7s" "TOTAL NUMBER OF VGs FOUND" : "$FD_VG" | tee -a $logfile
 print "\n" | tee -a $logfile
 printf "%-26s%2s%8.7s" "TOTAL NUMBER OF LVs NEEDED" : "$MX_LV"| tee -a $logfile
 print "" | tee -a $logfile
 printf "%-26s%2s%8.7s" "TOTAL NUMBER OF LVs FOUND" : "$LV_TOTAL"|tee -a $logfile
 print "\n" | tee -a $logfile
 printf "%-36s%2s%8.7s" "TOTAL NUMBER OF FILESYSTEMS NEEDED" : "$LV_FILES" | tee -a $logfile
 print "" | tee -a $logfile
 printf "%-36s%2s%8.7s" "TOTAL NUMBER OF FILESYSTEMS FOUND" : "$FS_FOUND" |tee -a $logfile
 print "\n" | tee -a $logfile
 if [[ -n $SNAPSHOT ]]; then
  sleep 5
 fi
}

verify_all()
{
 STANDALONE=""
 STANDALONE=$2
 cd $DRDIR

 case "$1" in
  snapshot) SNAPSHOT="YES"; shift;;
  *) SNAPSHOT="" ;;
 esac

 verify_questions()
 {
  sep_lin3
  print "Please chose from one of the selections below to Verify!"
  sep_lin3
  print " 1. Volumes Groups."
  print " 2. Logical Volumes."
  print " 3. NFS Mounts."
  print " 4. Paging Space."
  print " 5. 'A or a' for all!"
  print " 6. 'Q or q' to quit!"
  print "\n>\c"
 }

 if [[ $SNAPSHOT = YES ]]; then
  ModelType=$(uname -m | cut -c9-10)
  if [[ ! -n $STANDALONE ]]; then
   check_files YES
  fi
  print "\n"
  verify_questions
  while read input; do
   case $input in
      1) find_vgn snapshot
         found_vg;;
      2) build_logical_volume snapshot nobuild
         found_lv;;
      3) find_nfs snapshot;;
      4) find_page snapshot;;
  A|a|5) find_vgn snapshot
         found_vg
         con_tinue
         build_logical_volume snapshot nobuild
         found_lv
         con_tinue
         find_nfs snapshot
         con_tinue
         find_page snapshot;;
  Q|q|6) print "\nExiting DR_RESTORE Verify.\n"
         break;;
      *) print "Please enter either 1, 2, 3, 4, 5, 6, or 'A/a', 'Q/q'!\n"
   esac
     con_tinue
     clear
     verify_questions
  done
 else
  ModelType=$(uname -m | cut -c9-10)
  if [[ ! -n $STANDALONE ]]; then
   check_files YES
  fi
  find_vgn snapshot
  found_vg
  sleep 3
  build_logical_volume snapshot nobuild
  found_lv
  sleep 3
  if [[ ! -n $STANDALONE ]]; then
   find_nfs snapshot
   sleep 3
  fi
  find_page snapshot
 fi
}

find_all_snap()
{
 ModelType=$(uname -m | cut -c9-10)
 check_files snapshot
 con_tinue
 find_user snapshot
 con_tinue
 find_dasd snapshot
 con_tinue
 check_vgpv snapshot
 main_ssaraid_rebuild snapshot
 index_dasd_map snapshot
 con_tinue
 find_vgn snapshot
 vg_needed snapshot
 con_tinue
 disk_avail
 rebuild_vg snapshot
 rebuild_lvs snapshot
 con_tinue
 build_logical_volume snapshot
 build_logical_volume_cmds 
 con_tinue
 start_mklv
 con_tinue
 mirror_all snapshot
 con_tinue
 find_nfs snapshot
 con_tinue
 find_net snapshot
 verify_system snapshot
}

find_all_debug()
{
 ModelType=$(uname -m | cut -c9-10)
 check_files snapshot
 con_tinue
 clear
 find_user
 con_tinue
 print_ver
 find_dasd snapshot
 con_tinue
 check_vgpv snapshot
 main_ssaraid_rebuild snapshot
 index_dasd_map snapshot
 con_tinue
 find_vgn snapshot
 vg_needed snapshot
 con_tinue
 disk_avail
 rebuild_vg snapshot
 rebuild_lvs snapshot
 con_tinue
 build_logical_volume snapshot
 build_logical_volume_cmds 
 con_tinue
 start_mklv
 con_tinue
 mirror_all snapshot
 con_tinue
 find_nfs snapshot
 con_tinue
 find_net snapshot
 verify_system snapshot
}

##############################################
#  ###  BEGIN MAIN DR RESTORE ROUTINE ###    #
##############################################
#
################################################################################
# Set Global Variables, Check for command line options
################################################################################
export PATH=$PATH:/usr/lpp/ssp/bin:/usr/lpp/ssp/install/bin
RESTORE_DATE=`date '+%Y%m%d'`
SNAP_DATE=`date '+%Y%m%d'`
MACHINE=`uname -n`
ETYPE=D
NORDWS=0
GENRDWS=0
USAGE="Syntax: dr_restore.sh   [-f]</directory/filename> 
  \t\t\t[-d]</directory> 
  \t\t\t[-c] 
  \t\t\t[-i] 
  \t\t\t[-v]
  \t\t\t[-t]
  \t\t\t[-h]\n"
OFILE=""
EMAIL=""
SSARAID=""
def_arrays=""
SNAP=0
DEBUG=0
tmr=0
pdsk=0 
VERIFY=NO
CMDSO=NO
FILEFEED=NO
SNAPSHOT=NO
NEEDSARRAYS=NO
BUILD_FAILURE=NO
shell="#!/bin/ksh"
export DRDIR="/tmp/drinfo/"		  #Root directory for input/output
export OUTFILE="$MACHINE.$RESTORE_DATE"   #Output filename
export exclude_vg=""
# Get command line parameters (if any)
set -- `getopt bcd:f:ihHtTvV $* 2>/dev/null` 
if [ $? != 0 ]; then
 clear
 print "$USAGE"
 exit 1
fi
while [ $1 != -- ]
do
 case $1 in
  -b) print "DEBUG VALUE SET"
      DEBUG=YES;;
  -c) CMDSO=YES;;
  -d) DRDIR=$2
   if [[ $INFILE = "-f" || $INFILE = "-d" || $INFILE = "-i" \
   || $INFILE = "-h" || $INFILE = "-i" || $INFILE = "-h" || $INFILE = "-d" \
   || $INFILE = "-v" || $INFILE = "-H" ||  $INFILE = "-b" || $INFILE = "-t" ]]; then
	clear
	print "$USAGE"
	print "\aEnter in the correct syntax! i.e. \c"
	print "dr_restore.sh -d /tmp/snapshot\n"
   	exit 1
   fi
   if [ ! -d `echo $DRDIR` ]; then
	  clear
	  print "Input Failure!"
	  print "\aEnter a valid directory! i.e. /tmp/snapshot\n"
	  exit 1 
   fi
   OUTFILE="$MACHINE.$RESTORE_DATE" #Output filename
   shift;;
  -f) INFILE=$2
   if [[ $INFILE = "-f" || $INFILE = "-d" || $INFILE = "-i" \
   || $INFILE = "-h" || $INFILE = "-i" || $INFILE = "-h" || $INFILE = "-d" \
   || $INFILE = "-v" || $INFILE = "-H" ||  $INFILE = "-b" || $INFILE = "-t" ]]; then
	clear
	print "$USAGE"
	print "\aEnter in the correct syntax! i.e. \c"
	print "dr_restore.sh -f /tmp/"$MACHINE"_snapshot.Z\n"
   	exit 1
   fi
        INFILE="$INFILE"
        INFILET=`echo $INFILE|awk -F'/' '{print $NF}'`
        DRDIR=`echo $INFILE|sed s!$INFILET!!g`
        INFILE=$INFILET
        FILEFEED=YES
   if [ ! -d `echo $DRDIR` ]; then
	  clear
	  print "Input Failure!"
	  print "\aEnter a valid directory! i.e. /tmp/snapshot\n"
	  exit 1 
   fi
   touch $DRDIR$INFILE.log 2>/dev/null
   if [ $? -gt 0 ]; then
	  clear
	  print "Failure to create file!"
	  print "Log files cannot be created in $DRDIR!"
	  print "Check file permissions and verify filename format!\n"
	  exit 1
   fi
   rm $DRDIR$INFILE.log 2>/dev/null
   OUTFILE="$MACHINE.$RESTORE_DATE" #Output filename
   shift;;
  -i) SNAP="YES"
      SNAPSHOT=YES;;
   -t|T) check_for_latest_version
         exit 1;;
  -h|-H) clear
  	print "dr_restore.sh \n"
	print "[-c] : Print rebuild commands only, no actual rebuild!"
	print "[-d] : Look for input file in user defined </directory>."
	print "[-f] : Read input from user defined </directory/filename>."
	print "[-i] : Run 'dr_restore.sh' interactively."
	print "[-t] : Test for latest 'dr_restore.sh' script."
	print "[-v] : Verifies rebuilt VGs, LVs, FSs, PSs, and NFS mounts."
	print "[-h] : Command line HELP!\n"
	exit 1;;
  -v|-V) VERIFY=YES;;
   *)  clear
        print "$OPTARG is not a valid option"
	print "$USAGE";;
 esac
 shift
done

## Make DR directory, i.e. /tmp/dr_restore.$RESTORE_DATE
DRRSTDIR=/tmp/dr_restore.$RESTORE_DATE
if [[ ! -d $DRRSTDIR ]]; then
mkdir -p $DRRSTDIR
fi

if [[ ! -d `echo $DRRSTDIR` ]]; then 
 print "\aERROR CREATING DR_RESTORE DIRECTORY: $DRRSTDIR!"
 print "Please check size and permission of /tmp!"
 exit 1
fi

################################################################################
# BEGIN MAIN REBUILD ROUTINE
################################################################################
export logfile=$DRRSTDIR/$MACHINE.$RESTORE_DATE.restore.log
print "$RESTORE_DATE\n" > $logfile
if [[ $SNAPSHOT = YES ]]; then
 ver_check snapshot
else
 ver_check standard
fi
echo "Checking System Information" >> $logfile
ostype=`uname -s`
case $ostype in
 AIX) sysarch=pSERIES
  case $VERIFY in
   YES) if [[ $SNAPSHOT = YES ]]; then
         verify_all snapshot
        else
         verify_all 
        fi;;
    NO) case $DEBUG in
       YES) find_all_debug;; 
         0) case $SNAP in
           YES) find_all_snap;;
             0) ModelType=$(uname -m | cut -c9-10)
                check_files
                find_user
                find_dasd
                check_vgpv
                main_ssaraid_rebuild
                index_dasd_map
                find_vgn
                vg_needed 
                disk_avail
                rebuild_vg
                rebuild_lvs
                build_logical_volume 
                build_logical_volume_cmds 
                start_mklv
                mirror_all
                find_nfs 
                find_net
                verify_system;;
             *) clear
                print "UNSUPPORTED UNIX OPERATING SYSTEM\n"
                print "dr_restore.sh only supports AIX at this time!\n";;
            esac;;
        esac;;
  esac;;
     *) clear
        print "UNSUPPORTED UNIX OPERATING SYSTEM\n"
        print "dr_restore.sh only supports AIX at this time!\n";;
esac

rm -rf $DRRSTDIR/SSARAID_DASD.$RESTORE_DATE
################################################################################
# END MAIN REBUILD ROUTINE
################################################################################


