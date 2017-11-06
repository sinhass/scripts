#!/bin/bash
# Backup daily using week and date)
DATE=$(date +%Y%m%d)
mysqldump -uBACKUPUSER  --all-databases >/backups/bfasset01/mariadbdump/bfasset01-mariadb-$DATE.sql
find /backups/bfasset01/mariadbdump/ -type f -atime +15 -exec rm -f {} \;
