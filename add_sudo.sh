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

ssh -q $i "grep $USER_NAME $SUDOPATH" >/dev/null 2>&1
if [ $? -eq 0 ]; then
ssh -q $i "perl -ni -e 'print unless /$USER_NAME/'vi add_	  $SUDOPATH && perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1
else
ssh -q $i "perl -pi.bk -e 'print qq/$USER_NAME             ALL=(ALL)       NOPASSWD: ALL \n/ if eof;' $SUDOPATH" >/dev/null 2>&1			
fi

else

echo "Unable to access $i server"

fi

done

