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
	$hostbrname   = "",

	$guestextip   = undef,
	$hostexitif   = "eth0",
	$fwnat        = [],
	$fwfilter     = [],
	$config_dhcp  = true,
	$config_dns	  = true,
	$guestnicmodel= false,
	$networkmode  = "routed", # or bridged

	$guestdomain	= "",

	# disks params
	$guestdrbd    = false,
	$guestdisks   = [],
	# alternativ disk param method
	$guest_hda    = false,
	$guest_hdb    = false,
	$guest_hdc    = false,
	$guest_hdd    = false,
	$guest_hde	  = false,
	$isoimage     = "ubuntu-14.04.2-server-amd64.iso",
	$isoimagesrc  = "http://releases.ubuntu.com/14.04/ubuntu-14.04.2-server-amd64.iso",

	# dnsMadeEasy setting
	$dnsMadeEasyId 		= false,
	$dnsMadeEasyUser 		= false,
	$dnsMadeEasyPasswd 	= false,
	$dnsMadeEasyUrl 		= "http://www.dnsmadeeasy.com/servlet/updateip",

) {
	require kvmhost

	$etcpath	= $::kvmhost::kvmhost_etcpath
	$basepath 	= $::kvmhost::kvmhost_basepath

	if $hostbrname == "" {
	    $bridgename = $::kvmhost::bridgename
	} else {
	    $bridgename = $hostbrname
	}

	File{
    	ensure  => $ensure,
    	owner   => "root",
    	group   => "root",
    	mode    => "0440",
	}

	/* -----------------------------------
	 * generate node configuration
	 */
  	concat {"${etcpath}/${name}.conf":
    	require => File[$etcpath],
	}

	concat::fragment{"guest_${name}_conf":
	    content => template("kvmhost/guest/guest.conf.erb"),
	    target  => "${etcpath}/${name}.conf",
	    order	=> "00"
	}


  	concat {"${etcpath}/${name}.ifup":
	    require => File[$etcpath],
	    mode    => "0550",
	}

	concat::fragment{"guest_${name}_ifup":
	    content => template("kvmhost/guest/guest.ifup.erb"),
	    target  => "${etcpath}/${name}.ifup",
	    order	=> "00"
	}

  	concat{"${etcpath}/${name}.ifdown":
	    require => File[$etcpath],
	    mode    => "0550"
  	}

	concat::fragment{"guest_${name}_ifdown":
	    content => template("kvmhost/guest/guest.ifdown.erb"),
	    target  => "${etcpath}/${name}.ifdown",
	    order	=> "00"
	}


  	if $guestdomain != "" {
  	    $hostname = "${name}.${guestdomain}"
  	} else {
  	    $hostname = "${name}"
  	}

	if $guestintip and $config_dhcp and defined("dhcp::server") {
		dhcp::server::host {"${hostname}":
			address   => $guestintip,
			hwaddress => $guestmacaddr,
		}
	}

	if $config_dns {
		if $guestdomain != "" and $guestintip  {
		    if defined(::Dns::Zone[$guestdomain]) {
				$dns_iparr		= split($guestintip,'[.]')
				$dns_reverszone = "${dns_iparr[2]}.${dns_iparr[1]}.${dns_iparr[0]}.IN-ADDR.ARPA"
				if defined(::Dns::Zone[$dns_reverszone]) {
					$arecPtr = true
				} else {
					$arecPtr = false
					if kvmhost::verbose {
					    notify{"guest ${name}: no reverse ptr for ${dns_reverszone}":}
					}
				}

				if !defined(Dns::Record::A["${name}"]) {
					dns::record::a { "${name}":
			      		zone  => $guestdomain,
			      		data  => $guestintip,
			      		ptr   => $arecPtr
			    	}
				}
		    } elsif kvmhost::verbose {
		        notify{"guest ${name}: dns zone: ${guestdomain} not defined": }
		    }
		} elsif kvmhost::verbose == true {
			notify{"guest ${name}: no landomain: ${guestdomain} or no int-ip: ${guestintip}":}
		}
	}


	if $autostart and $ensure == 'present' {
		file{"${etcpath}/autostart/${name}.conf":
		  ensure => link,
		  target => "${etcpath}/${name}.conf",
		  require => [File["${etcpath}","${etcpath}/autostart/"],Concat["${etcpath}/${name}.conf"]],
		}
	} else {
		file{"${etcpath}/autostart/${name}.conf":
			ensure => absent
		}
	}

}
