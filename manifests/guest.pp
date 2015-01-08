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

define kvmhost::guest(
  $ensure = present,
  $guestintip  = undef,
  $guestmacaddr = undef,
  $guestextip  = undef,
  $guestcpus   = "1",
  $guestmemory = "1024",
  $guestdisks   = [],
  $guestdrbd    = "",
  $vncid        = "",

  $autostart = "0",
  $fwnat      = [],
  $fwfilter   = [],
  $dnsMadeEasyId = "",
  $dnsMadeEasyUser = "",
  $dnsMadeEasyPasswd = "",
  $dnsMadeEasyUrl = "http://www.dnsmadeeasy.com/servlet/updateip",
  
  $isoimage = "ubuntu-14.04.1-server-amd64.iso"
) {

  /* FIX_ME make config class */
  case $kvmhost_basepath {
    '': { $kvmhost_basepath = "/srv/kvm" }
  }

  case $kvmhost_etcpath {
    '': { $kvmhost_etcpath = "${kvmhost_basepath}/etc" }
  }


  file {"${kvmhost_etcpath}/${name}.conf":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0440,
    content => template("kvmhost/guest/guest.conf.erb"),
  }


  file {"${kvmhost_etcpath}/${name}.ifup":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0555,
    content => template("kvmhost/guest/guest.ifup.erb"),
  }


  file {"${kvmhost_etcpath}/${name}.ifdown":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0555,
    content => template("kvmhost/guest/guest.ifdown.erb"),
  }

  if (defined("monit::check::file")) {
    monit::check::file{"kvmmonit_${name}_conf":
          filepath => "${kvmhost_etcpath}/${name}.conf"
    }
    
    monit::check::file{"kvmmonit_${name}_ifup":
          filepath => "${kvmhost_etcpath}/${name}.ifup"
    }
    
	  monit::check::file{"kvmmonit_${name}_ifdown":
	        filepath => "${kvmhost_etcpath}/${name}.ifdown"
	  }      
  }
}
