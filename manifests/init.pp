# A puppet module to configure a kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#
#

class kvmhost (
  $basepath         = '/srv/kvm',
  $etcpath          = '',
  $hdimagepath      = '',
  $cdrompath        = '',
  $defaultiso       = 'ubuntu-14.04.1-server-amd64.iso',
  $defaultisourl    = '',
  $ifprefix         = '',
  $def_bridgename   = 'br0',
  $piddir           = ''
) {

  case $basepath {
    '': { $kvmhost_basepath = "/srv/kvm" }
    default: { $kvmhost_basepath = "${basepath}" }
  }

  case $etcpath {
    '': { $kvmhost_etcpath = "${basepath}/etc" }
    default: { $kvmhost_etcpath = "${etcpath}" }
  } 

  case $hdimagepath {
    '': { $kvmhost_hdimagepath = "${kvmhost_basepath}/images" }
    default: { $kvmhost_hdimagepath = "${hdimagepath}" }
  }

  case $cdrompath {
    '': { $kvmhost_cdrompath = "${kvmhost_basepath}/cdrom" }
    default: {$kvmhost_cdrompath = $cdrompath}
  }
    
  case $defaultiso {
    '': { $kvmhost_defaultiso = "ubuntu-14.04.1-server-amd64.iso" }
    default: { $kvmhost_defaultiso = $defaultiso }
  }

  case $ifprefix {
    '': { $kvmhost_ifprefix = "kvm" }
    default: { $kvmhost_ifprefix = $ifprefix }
  }

 case $def_bridgename {
   '': { $kvmhost_brigename = "${kvmhost_ifprefix}br0" }
   default: { $kvmhost_brigename = $def_bridgename }
 }

 case $piddir {
   '': { $kvmhost_piddir = "/var/run/kvm" }
   default: { $kvmhost_piddir = $piddir }
 }

  package { ["curl","postfix"]:
    ensure => installed,
  }

  # the base directory structure
  file { [
      "${kvmhost_basepath}/",
      "${kvmhost_basepath}/bin/",
      "${kvmhost_basepath}/bin/includes/",
      "${kvmhost_cdrompath}/",
      "${kvmhost_hdimagepath}/",
      "${kvmhost_etcpath}/",
      "${kvmhost_piddir}/" ]:
    ensure => "directory",
    owner   => "root",
    group   => "root",
    mode    => "0750",
  }

  if $defaultiso == "ubuntu-14.04.1-server-amd64.iso" {
	  exec {"donload-ubuntu-14.04.1-server-amd64.iso":
	    command => "/usr/bin/wget -O ${kvmhost_cdrompath}/ubuntu-14.04.1-server-amd64.iso http://releases.ubuntu.com/14.04.1/ubuntu-14.04.1-server-amd64.iso",
	    creates => "${kvmhost_basepath}/cdrom/ubuntu-14.04.1-server-amd64.iso",
	    require => File["${kvmhost_cdrompath}/"]
	  }  
  } elsif $defaultiso != '' and $defaultisourl != ''  {
    exec {"donload-${defaultiso}":
      command => "/usr/bin/wget -O ${kvmhost_cdrompath}/${defaultiso} ${defaultisourl}",
      creates => "${kvmhost_cdrompath}/${defaultiso}",
      require => File["${kvmhost_cdrompath}/"]
    }     
  }
  
  /*
  exec {"donload-ubuntu-12.04.5-server-amd64.iso": 
    command => "/usr/bin/wget -O ${kvmhost_basepath}/cdrom/ubuntu-12.04.5-server-amd64.iso http://releases.ubuntu.com/12.04/ubuntu-12.04.5-server-amd64.iso",
    creates => "${kvmhost_basepath}/cdrom/ubuntu-12.04.5-server-amd64.iso",
    require => File["${kvmhost_cdrompath}/"]  
  }   
  */

  # main init scripts

  file { "${kvmhost_basepath}/bin/includes/checkdrbd.sh.inc":
    owner   => "root",
    group   => "root",
    mode    => '0444',
    content => template("kvmhost/includes/checkdrbd.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/includes/checkdisks.sh.inc":
    owner   => "root",
    group   => "root",
    mode    => '0444',
    content => template("kvmhost/includes/checkdisks.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/includes/checkcdrom.sh.inc":
    owner   => "root",
    group   => "root",
    mode    => '0444',
    content => template("kvmhost/includes/checkcdrom.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/includes/checknetwork.sh.inc":
    owner   => "root",
    group   => "root",
    mode    => '0400',
    content => template("kvmhost/includes/checknetwork.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/init.sh":
    owner   => "root",
    group   => "root",
    mode    => '0550',
    content => template("kvmhost/init.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/ifup.sh":
    owner   => "root",
    group   => "root",
    mode    => '0555',
    content => template("kvmhost/ifup.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/ifdown.sh":
    owner   => "root",
    group   => "root",
    mode    => '0555',
    content => template("kvmhost/ifdown.sh.erb"),
  }

}
