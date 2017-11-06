#!/usr/bin/ksh
# Author : Siddhartha S Sinha
#
echo "Before you start make sure you are using SCSI attached DVD RAM Drive"
echo ""
diag -c -d cd1 -T format -s initialize
cd /utility
mkdvd -d cd1 -r . -I /images


