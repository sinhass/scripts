/local:
  file.directory:
    - user: cadmin
    - group: hw
    - recurse:
      - group
    - makedirs: True
    - dir_mode: 777

/local/tmp:
  file.directory:
    - user: cadmin
    - group: hw
    - makedirs: True
    - dir_mode: 777
