#! / Bin / sh 

  ################################################## ########### 
  # This gives basic sysinfo 
  ################################################## ########## 

  Echo "The System-Hostname` hostname = `" 
  Echo "The System-Uptime =` uptime | awk '(print,)' `" 
  Sm `prtconf-pv = | grep banner-name | awk-F" ' "' (print) '` 
  Echo "The system-make = $ sm" 
  Mm = `prtconf-pv | grep Mem | awk '(print,)'` 
  Echo "The system-memory = $ mm" 
  Echo "The Sytem-process-count = $ ps" 
  Mc = `ifconfig-a | awk '/ ether / (print)'` 
  Echo "The System-MacAddress = $ mc" 
  Bt = `` isainfo-kv 
  Echo "The System-kernel-type = $ bt" 