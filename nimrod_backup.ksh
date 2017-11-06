#!/usr/bin/ksh
# Author - Siddhartha S Sinha
# This Script will take the mksysb and then stack the savevg's of nimvg and vgnim on the
# same tape. The tape must be LTO3 or LTO4.
#
chdev -l rmt1 -a block_size=0
mt -t /dev/rmt1 rewind
mksysb -ipXf /dev/rmt1
mt -t /dev/rmt1.1 fsf 4
savevg -ipXf /dev/rmt1.1 nimvg
savevg -ipXf /dev/rmt1.1 vgnim

