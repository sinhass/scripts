#!/bin/sh
# -----------------------------------------------------------------------------
# run.sh - v.0.1 - full Disk, VGs, LVs and  Filesystem Information , 2005.10.01
# -----------------------------------------------------------------------------
# df.sh - script - full Disk, VGs, LVs and  Filesystem Information , 2005.10.01
# -----------------------------------------------------------------------------

DDIR=`date +%y%m%d.%H%M%S`
FL=aixstorage.`uname -n`

df.sh |tee $FL
if [ -d /tmp/ibmsupt ] ; then
SNAPDIR=/tmp/ibmsupt
fi
echo "use information from $SNAPDIR"
aix_snap.pl $SNAPDIR $FL > $FL.out
mv aixstorage.html  $FL.html

echo "output file :  $FL.html"

