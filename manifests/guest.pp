# A puppet module to configure a kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#

define kvmhost::guest(
  $ensure = present,
  $vncid        = "",
  $autostart    = false,
  $guestcpus    = "1",
  $guestmemory  = "1024",

  #network params    
  $guestintip   = undef,
  $guestmacaddr = undef,
  $guestextip   = undef,
  $fwnat        = [],
  $fwfilter     = [],
  $config_dhcp  = true,
  $guestnicmodel= false,
  
  # disks params
  $guestdrbd    = false,
  $guestdisks   = [],  
  # alternativ disk param method
  $guest_hda    = false,
  $guest_hdb    = false,
  $guest_hdc    = false,
  $guest_hdd    = false,
  $isoimage = "ubuntu-14.04.1-server-amd64.iso",
  
  # dnsMadeEasy setting
  $dnsMadeEasyId = false,
  $dnsMadeEasyUser = false,
  $dnsMadeEasyPasswd = false,
  $dnsMadeEasyUrl = "http://www.dnsmadeeasy.com/servlet/updateip",
  
  
  
) {

  $kvmhost_etcpath  = $::kvmhost::kvmhost_etcpath
  $kvmhost_basepath = $::kvmhost::kvmhost_basepath
  
  file {"${kvmhost_etcpath}/${name}.conf":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => "0440",
    content => template("kvmhost/guest/guest.conf.erb"),
  }


  file {"${kvmhost_etcpath}/${name}.ifup":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => "0555",
    content => template("kvmhost/guest/guest.ifup.erb"),
  }


  file {"${kvmhost_etcpath}/${name}.ifdown":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => "0555",
    content => template("kvmhost/guest/guest.ifdown.erb"),
  }

  if $config_dhcp {

    dhcp::server::host {"${name}":
        address   => $guestintip,
        hwaddress => $guestmacaddr,
    }    
  }

}
