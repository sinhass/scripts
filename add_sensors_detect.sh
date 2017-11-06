echo -n "Type the server Name:"
for i in {1..100}
do
echo servername$i
ssh -q servername$i -o ConnectTimeout=3 "yes YES|sensors-detect && service snmpd restart"
done
