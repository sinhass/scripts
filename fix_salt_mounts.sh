#for X in `cat /tmp/ct_notworking`
for X in cs{1..32}.barefoot.int-lan
do 
#X=ct138.barefoot-int.lan
#ssh -o "StrictHostKeyChecking no" $X 'pkill salt-minion && salt-minion -d'
ssh -q -o  "StrictHostKeyChecking no" $X 'pkill salt-minion ; salt-minion -d'
salt "$X"  file.line /etc/fstab backup='true' content='fs2' match='fs2' mode='delete'
salt "$X"  file.line /etc/fstab backup='true' content='fs1' match='fs1' mode='delete'
salt "$X"  file.line /etc/fstab backup='true' content='nessie' match='nessie' mode='delete'
salt -t 5 "$X" state.apply fs2_mounts
salt -t 5 "$X" state.apply fs1_mounts
done
