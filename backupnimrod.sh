#!/usr/bin/ksh
# This script will backup everything of NIMROD
# And will be called from cron file
# Author : Siddhartha S Sinha
#
#
mksysb -i /nimbckup/mksysb.nimrod.`date +"%m%d%Y"`   
savevg -i -f /nimbckup/nimrod.savevg.nimvg.`date +"%m%d%Y"` nimvg
savevg -i -f /nimbckup/nimrod.savevg.vgnim.`date +"%m%d%Y"` vgnim
