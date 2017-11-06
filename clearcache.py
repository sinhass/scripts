#!/usr/bin/python
# Author Siddhartha S Sinha
import re, os, string, socket
host_name = socket.gethostname()
free_mem = os.system('free -g|grep Mem|awk "{print $4}"')
print(free_mem)
clear_cache = os.system('sync; echo 1 >/proc/sys/vm/drop_caches')


def memory_threshold():
    if 'pd' in host_name:
        mem_thresh = 150
    elif 'cs' in host_name:
        mem_thresh = 250
    elif 'sge' in host_name:
        mem_thresh = 100
    elif 'ct' in host_name:
        mem_thresh = 1
    elif 'hydra' in host_name:
        mem_thresh = 100
    else:
        mem_thresh = 200
    return mem_thresh


if __name__ == '__main__':
    if free_mem <= memory_threshold():
        clear_cache






