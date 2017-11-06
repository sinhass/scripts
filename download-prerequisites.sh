#!/bin/ksh

PATH=/usr/bin:/bin
FTP_SITE="ftp.software.ibm.com"
FTP_PID=0
PROGRESS_PID=0
RPM_DIR_ROOT="/aix/freeSoftware/aixtoolbox/RPMS/ppc"
CURRENT_FILE=""

# This is the cleanup function which is called if the user kills the download
# via Ctrl-C or by manually killing the process from the command line with
# the kill command.
function cleanup {
    if [[ $FTP_PID -gt 0 ]]; then
        print "Killing background FTP pid: $FTP_PID"
        kill -TERM $FTP_PID
    fi
    if [[ $PROGRESS_PID -gt 0 ]]; then
        print "Killing background progress pid: $PROGRESS_PID"
        kill -TERM $PROGRESS_PID
    fi
    if [[ -n $CURRENT_FILE && -e $CURRENT_FILE ]]; then
        print "Removing partially downloaded file: $CURRENT_FILE"
        rm -f $CURRENT_FILE
    fi
}

#
# Input:
#   filename - The name of the file which is downloading.
#   size     - The expected filesize for the file from the 2st column of
#              /usr/bin/cksum output.
#
# This function is meant to be called from a separate process, and it
# continuously prints the filesize of the file on the local machine 
# compared to the expected filesize, providing a crude progress meter.
# 
function progress_filesize {
    filename=$1
    filesize=$2
    while [[ "$local_filesize" != "$filesize" ]]; do
        local_filesize=`ls -l $filename 2>/dev/null | awk '{print $5}'`
        if [[ -z $local_filesize ]]; then
            local_filesize=0
        fi
        str="$local_filesize/$filesize"
        length=${#str}
        print -n -- "$str"
        integer i=0
        while  [[ i -lt $length ]]; do
            print -n -- ""
            i=i+1
        done
        sleep 1
    done
}

#
# Input:
#   filename - the name of the file to validate
#   sum      - The expected checksum for the file from the 1st column of
#              /usr/bin/cksum output.
#   size     - The expected filesize for the file from the 2st column of
#              /usr/bin/cksum output.
# 
# Returns:
#   Returns 0 if the file is found and has the correct checksum and filesize
#   and 1 otherwise.
#
function validate_file {
    filename=$1
    sum=$2
    size=$3
    valid_file=1
    if [[ -f $filename ]]; then
        cksum=`cksum $filename`
        cksum_sum=`echo $cksum | awk '{print $1}'`
        cksum_size=`echo $cksum | awk '{print $2}'`
        failed_cksum=0
        if [[ "$cksum_sum" = "$sum" && "$cksum_size" = "$size" ]]; then
            valid_file=0
        fi
    fi
    return $valid_file
}

#
# Input:
#   sum      - The expected checksum for the file from the 1st column of
#              /usr/bin/cksum output.
#   size     - The expected filesize for the file from the 2st column of
#              /usr/bin/cksum output.
#   filename - The name of the file to download.
# 
# This function first checks to see if the file has already been downloaded,
# and will exit early in that case. After that, it will attempt to download
# the file from the FTP site and if the file has the correct checksum after
# downloading, the function will return. If the checksum is invalid, then
# the script will exit and the invalid file will be removed.
#
function download_and_checksum {
    sum=$1
    size=$2
    filename=$3

    subdir=`echo $filename | cut -d- -f1`
    ftpfilename=$filename
    if [[ "$subdir" = "gtk+" ]]; then
        ftpfilename=`echo $filename | sed 's|gtk+|gtkplus|g'`
        subdir=`echo $ftpfilename | cut -d- -f1`
    fi
    ftpdir="$RPM_DIR_ROOT/$subdir"
    ftppath="$ftpdir/$ftpfilename"

    validate_file $filename $sum $size
    if [[ $? -eq 0 ]]; then
        print "$filename already downloaded - skipping."
        return
    fi

    CURRENT_FILE="$filename"
    print -n "Downloading $FTP_SITE$ftppath... "
    progress_filesize $filename $size &
    PROGRESS_PID=$!
    cat <<EOF | ftp -in $FTP_SITE > /dev/null 2>&1 &
user anonymous anonymous
passive
binary
cd $ftpdir
get $ftpfilename $filename
quit
EOF
    FTP_PID=$!
    wait $FTP_PID
    kill $PROGRESS_PID
    PROGRESS_PID=0
    FTP_PID=0
    CURRENT_FILE=""
    validate_file $filename $sum $size
    if [[ $? -eq 0 ]]; then
        print "DONE                        "
    else
        print "FAILED                      "
        rm -f $filename
        exit 1
    fi
}

# This allows us to stop the download if the user types Ctrl-c
trap 'rc=$?; print "Download interrupted... Cleaning up."; cleanup; exit $rc' INT TERM QUIT HUP

# We feed all of these files into the download_and_checksum function.
cat <<EOF | while read info; do download_and_checksum $info; done
1992189204 296113 atk-1.10.3-2.aix5.1.ppc.rpm
410202956 642912 cairo-1.0.2-6.aix5.1.ppc.rpm
3213026384 459599 expat-1.95.7-4.aix5.1.ppc.rpm
3208700441 354041 fontconfig-2.2.2-5.aix5.1.ppc.rpm
360828734 575176 freetype2-2.1.7-5.aix5.1.ppc.rpm
3313693538 710948 gettext-0.10.40-6.aix5.1.ppc.rpm
690098906 1322766 glib2-2.8.1-3.aix5.1.ppc.rpm
3060936556 9156344 gtk2-2.8.3-9.aix5.1.ppc.rpm
3000838206 267086 libjpeg-6b-6.aix5.1.ppc.rpm
1310763360 671990 libpng-1.2.8-5.aix5.1.ppc.rpm
4169058336 616366 libtiff-3.6.1-4.aix5.1.ppc.rpm
3611503884 858953 pango-1.10.0-2.aix5.1.ppc.rpm
703546213 55580 xcursor-1.0.2-3.aix5.1.ppc.rpm
3429223428 120078 xft-2.1.6-5.aix5.1.ppc.rpm
3933256318 46263 xrender-0.8.4-7.aix5.1.ppc.rpm
2426580530 110689 zlib-1.2.3-3.aix5.1.ppc.rpm
EOF
