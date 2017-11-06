/root/clearcache:
  file.managed:
    - source: salt://managed_files/clearcache
    - user: root
    - group: root
    - mode: 755
