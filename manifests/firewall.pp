# A puppet module to configure a kvm host / guest firwall
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#


define kvmhost::firewall(
	$ensure 	= present,
	$hostid  	= "00",
	$trustedips = [],
	$routes	  	= [],
	$sshport	= "2200"

) {
	$bridgeif 	= $::kvmhost::def_bridgename
	$extif 		= $::kvmhost::extif
	$vlan_net	= $::kvmhost::localnet

	File{
		ensure  => $ensure,
	    owner   => 'root',
	    group   => 'root',
	    mode    => '0550',
	}

  	if !defined(File["/etc/firewall"]) {
		file {"/etc/firewall":
	    	ensure => directory,
	    	mode    => '0750',
	  	}
	}

	file {"/etc/firewall/000-init.sh":
	    content => template("kvmhost/firewall/init.sh.erb"),
	}

	file {"/etc/firewall/010-routing.sh":
		content => template("kvmhost/firewall/routing.sh.erb"),
	}

    file {"/etc/firewall/020-trusted.sh":
		ensure  => $ensure,
		owner   => "root",
		group   => "root",
		mode    => "0550",
		content => template("kvmhost/firewall/trusted.sh.erb"),
    }

	file {"/etc/init.d/kvmfirewall":
		content => template("kvmhost/firewall/kvmfirewall.erb"),
		require => File["/etc/firewall/000-init.sh","/etc/firewall/010-routing.sh"],
		notify  => Exec["update-rc-kvmfirewall"],
	}

	exec {"update-rc-kvmfirewall":
		command => "/usr/sbin/update-rc.d kvmfirewall defaults",
		require => File["/etc/init.d/kvmfirewall"],
		refreshonly => true
    }
}
