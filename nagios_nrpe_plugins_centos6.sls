#/usr/lib64/nagios/plugins/check_sys_temp.pl:
#  file.managed:
#   - source: salt://managed_files/check_sys_temp.pl
#   - user: root
#   - group: root
#   - mode: 755
#
#/usr/lib64/nagios/plugins/check_lm_sensors:
#  file.managed:
#   - source: salt://managed_files/check_lm_sensors
#   - user: root
#   - group: root
#   - mode: 755
copy_plugins:
  file.recurse:
   - name: /usr/lib64/nagios/plugins/
   - source: salt://nagios_centos6
   - file_mode: 755
   - user: root
   - group: root
