# A puppet module to configure a drbd for kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#

define kvmhost::drbd::discdevice (
  $ensure     		= present,
  $minor      		= undef,
  $portnbr	  		= undef,
  $disk       		= undef,
  $drbdMasterName 	= undef,
  $drbdMasterIp   	= undef,
  $drbdSlaveName  	= undef,
  $drbdSlaveIp    	= undef,
  $createmd			= true,
) {

   	if !$portnbr {
   	    $port = "77${portnbr}"
   	} else {
   	    $port = $portnbr
   	}

    if !defined(Host[$drbdMasterName]) {
        host{"${drbdMasterName}":
            ip => $drbdMasterIp
		}
    }

    if !defined(Host[$drbdSlaveName]) {
        host{"${drbdSlaveName}":
            ip => $drbdSlaveIp
		}
    }

	file {"/etc/drbd.d/$name.res":
		ensure  => $ensure,
		owner   => "root",
		group   => "root",
		mode    => "0550",
		content => template("kvmhost/drbd/resource.res.erb"),
	}

	if $createmd {
		exec { "create_drbd_${name}":
			command => "/sbin/drbdadm create-md ${name}; /sbin/drbdadm up ${name}",
			creates => "/dev/drbd/by-res/${name}",
			require => File["/etc/drbd.d/$name.res"]
	    }
    }


	if has_ip_address($drbdMasterIp) {
	    $fwfilterappendrules = ["INPUT -s ${drbdSlaveIp} -p tcp --dport ${port} -j ACCEPT"]
	} else {
	    $fwfilterappendrules = ["INPUT -s ${$drbdMasterIp} -p tcp --dport ${port} -j ACCEPT"]
	}

  	if !defined(File["/etc/firewall"]) {
		file {"/etc/firewall":
	    	ensure => directory,
	    	mode    => '0750',
	  	}
	}

	file { "/etc/firewall/099-drbd-${name}.sh":
		ensure  => $ensure,
		owner   => "root",
		group   => "root",
		mode    => "0770",
		content => template("kvmhost/firewall/specialrules.sh.erb"),
		require => File["/etc/firewall"]
	}

}

