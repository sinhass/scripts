    #!/bin/sh

    #
    # solinfo.sh
    #
    #
    # 2008 - Mike Golvach - eggi@comcast.net
    #
    # Creative Commons Attribution-Noncommercial-Share Alike 3.0 United States License
    #

    echo "hostname: \c"
    /usr/bin/hostname
    echo

    echo "model: \c"
    /usr/bin/uname -mi
    echo

    echo "cpu count: \c"
    /usr/bin/dmesg|grep cpu|sed 's/.*\(cpu.*\)/\1/'|awk -F: '{print $1}'|sort -u|wc -l
    echo

    echo "disks online: \c"
    echo "^D"|format 2>/dev/null|grep ".\. "|wc -l
    echo

    echo "disk types:"
    echo
    echo "^D"|format 2>/dev/null|grep ".\. "
    echo

    echo "dns name and aliases:"
    echo
    nslookup `hostname`|grep Name;nslookup `hostname`|sed -n '/Alias/,$p'
    echo

    echo "Interfaces:"
    echo
    netstat -in|grep -v Name|grep -v lo0|awk '{print "Name: " $1 " : IP: " $4}'
    echo

    echo "Access Restrictions:"
    echo
    if [ -f /etc/hosts.allow ]
    then
    cat /etc/hosts.allow
    else
    echo "No host based access restrictions in place"
    fi
    echo
    echo "OS Release: \c"
    uname -r