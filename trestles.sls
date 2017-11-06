/proj/trestles:
    mount.mounted:
      - device: fs2.barefoot-int.lan:/mnt/fs2pool6tb/trestles
      - fstype: nfs
      - mkmnt: True
      - opts: ro,bg,vers=3,noacl

