/scratch:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl
/scratch/dv:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch/dv
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch/pd:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch/pd
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch/dft:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch/dft
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch/emulation:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch/emulation
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch/chipdv:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/scratch/chipdv
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl

/scratch3/chipdv:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/chipdv
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3/dft:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/dft
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3/dv:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/dv
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3/emulation:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/emulation
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3/ip:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/ip
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/scratch3/pd:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/scratch1pool/scratch3/pd
      - fstype: nfs
      - mkmnt: False
      - opts: bg,vers=3,noacl

/home:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/home
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl

/proj:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/proj
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl

/tools:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/tools
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl

/ip:
    mount.mounted:
      - device: fs1.barefoot-int.lan:/mnt/fs1pool/ip
      - fstype: nfs
      - mkmnt: True
      - opts: bg,vers=3,noacl

/proj/tofino_b0:
    mount.mounted:
    - device: fs1.barefoot-int.lan:/mnt/fs1pool/proj/tofino_b0
    - fstype: nfs
    - mkmnt: False
    - opts: bg,vers=3,noacl

/proj/jbay:
    mount.mounted:
    - device: fs1.barefoot-int.lan:/mnt/fs1pool/proj/jbay
    - fstype: nfs
    - mkmnt: False
    - opts: bg,vers=3,noacl
