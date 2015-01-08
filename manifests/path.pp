  case $kvmhost_basepath {
    '': { $kvmhost_basepath = "/srv/kvm" }
  }

  case $kvmhost_etcpath {
    '': { $kvmhost_etcpath = "${kvmhost_basepath}/etc" }
  }

  case $kvmhost_hdimagepath {
    '': { $kvmhost_hdimagepath = "${kvmhost_basepath}/images" }
  }

  case $kvmhost_cdrompath {
    '': { $kvmhost_cdrompath = "${kvmhost_basepath}/cdrom" }
  }

  case $kvmhost_defaultiso {
    '': { $kvmhost_defaultiso = "ubuntu-14.04.1-server-amd64.iso"}
  }

  case $kvmhost_ifprefix {
    '': { $kvmhost_ifprefix = "kvm" }
  }

 case $kvmhost_brigename {
   '': { $kvmhost_brigename = "${kvmhost_ifprefix}br0" }
 }

 case $kvmhost_piddir {
   '': { $kvmhost_piddir = "/var/run/kvm" }
 }

