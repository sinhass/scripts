for SERVER_NAMES in cs{1..23}
do
ssh -q -o ConnectTimeout=3 sed -i -re "s/^(allowed_hosts)=(.*)/\1=10.201.202.254\,10.201.202.40/" /etc/nagios/nrpe.cfg && service nrpe restart
done
