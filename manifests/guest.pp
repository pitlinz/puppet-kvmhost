# A puppet module to configure a kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
# disk hash: (guest_hda,guest_hdb ....)
# {
# }
#

define kvmhost::guest(
  $ensure       = present,
  $autostart    = false,
  $vncid        = "",

  $guestcpus    = "1",
  $guestmemory  = "1024",

  #network params
  $guestintip   = false,
  $guestmacaddr = undef,
  $hostbrname   = "${kvmhost::host::br_name}",

  $guestextip   = undef,
  $hostexitif   = "eth0",
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
  $guest_hde	= false,
  $isoimage     = "ubuntu-14.04.1-server-amd64.iso",

  # dnsMadeEasy setting
  $dnsMadeEasyId 		= false,
  $dnsMadeEasyUser 		= false,
  $dnsMadeEasyPasswd 	= false,
  $dnsMadeEasyUrl 		= "http://www.dnsmadeeasy.com/servlet/updateip",

) {
	require kvmhost

	$etcpath	= $::kvmhost::kvmhost_etcpath
	$basepath 	= $::kvmhost::kvmhost_basepath

	File{
    	ensure  => $ensure,
    	owner   => "root",
    	group   => "root",
    	mode    => "0440",
	}

	/* -----------------------------------
	 * generate node configuration
	 */
  	file {"${etcpath}/${name}.conf":
    	content => template("kvmhost/guest/guest.conf.erb"),
    	require => File[$etcpath],
	}

  	file {"${etcpath}/${name}.ifup":
	    content => template("kvmhost/guest/guest.ifup.erb"),
	    require => File[$etcpath],
	    mode    => "0550",
	}

  	file {"${etcpath}/${name}.ifdown":
	    content => template("kvmhost/guest/guest.ifdown.erb"),
	    require => File[$etcpath],
	    mode    => "0550"
  	}

  if $config_dhcp and defined("dhcp::server") {
    dhcp::server::host {"${name}":
        address   => $guestintip,
        hwaddress => $guestmacaddr,
    }
  }

  if ($::kvmhost::host::lan_domain != "localnet") and $guestintip {
    if defined(::Dns::Zone[$::kvmhost::host::lan_domain]) {
      if defined(::Dns::Zone[ $::kvmhost::host::dns_reverszone ]) {
        $arecPtr = true
      } else {
        $arecPtr = false
      }
	    dns::record::a { "${name}":
	      zone  => $::kvmhost::host::lan_domain,
	      data  => $guestintip,
	      ptr   => $arecPtr
	    }
    }
  }


  if $autostart and $ensure == 'present' {
    file{"${etcpath}/autostart/${name}.conf":
      ensure => link,
      target => "${etcpath}/${name}.conf",
      require => File["${etcpath}","${etcpath}/autostart/","${etcpath}/${name}.conf"],
    }
  } else {
    file{"${etcpath}/autostart/${name}.conf":
      ensure => absent
    }
  }

}
