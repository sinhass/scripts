#!/bin/bash
# Siddhartha Sinha
#
HOSTNAME=$(hostname -s)
MEM_FREE=$(free -g|grep Mem|awk '{print $4}')
CLEAR_MEM () {
  if [[ "$MEM_FREE" -lt "$LOWMEM" ]]; then
    sync; echo 1 >/proc/sys/vm/drop_caches
  fi
}
LOW_MEM () {
  if [[ "$HOSTNAME" =~ pd.* ]]; then
    LOWMEM=150
  elif [[ "$HOSTNAME" =~ sge.* ]]; then
    LOWMEM=100
  elif [[ "HOSTNAME" =~ cs.* ]]; then
    LOWMEM=300
  elif [[ "HOSTNAME" =~ hydra.* ]];then
    LOWMEM=150
  elif [[ "HOSTNAME" =~ ct.* ]]; then
    LOWMEM=1
  else
    LOWMEM=50
  fi
  }
LOWMEM=$(LOW_MEM)
CLEAR_MEM
