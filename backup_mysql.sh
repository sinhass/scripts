#!/bin/bash
# Backup daily using week and date)
DATE=$(date +%Y%m%d)
mysqldump -uBACKUPUSER  --all-databases >/backups/bigfoot/mysqldump/bigfoot_alldb_dump-$DATE.sql
find /backups/bigfoot/mysqldump/ -type f -atime +15 -exec rm -f {} \;
