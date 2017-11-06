#!/usr/bin/ksh
# Author : Siddhartha Sinha
# Email  : sidsinha@us.ibm.com
#
#
OS_LEVEL=`oslevel -r|cut -c 1-4`
	if 	[ "$OS_LEVEL" = "5300" ]; then
echo " THIS IS AIX 5.3"

elif
	[ "$OS_LEVEL" = "6100" ]; then
echo "THIS IS AIX 6.1"
elif
	[ "$OS_LEVEL" = "5200" ]; then
echo "THIS IS AIX 5.2"
fi
