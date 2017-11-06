for SERVER_NAMES in pd{{1..32}
do
ssh -q -o ConnectTimeout=3 $SERVER_NAMES 'yum install nrpe nagios -y && sed -i -re "s/^(allowed_hosts)=(.*)/\1=10.201.202.254\,10.201.202.40/" /etc/nagios/nrpe.cfg && service nrpe restart && chkconfig nrpe on'
done

