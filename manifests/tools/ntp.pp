/**
 * class to install network time server
 */
define kvmhost::tools::ntp(
    $timeservers = [
        '0.debian.pool.ntp.org',
		'1.debian.pool.ntp.org',
		'2.debian.pool.ntp.org',
		'3.debian.pool.ntp.org',
    ],
    $restrictions = [
        '192.168.0.0 mask 255.255.0.0'
    ],
	$broadcast = "",
){
	package{"ntp":
	    ensure => installed
	}

	file{"/etc/ntp.conf":
	    owner 	=> "root",
		group 	=> "root",
		mode 	=> "0644",
		ensure	=> present,
		content => template("kvmhost/tools/ntp.conf.erb"),
		require	=> Package["ntp"],
	}

	if defined(File["/etc/firewall"]) {
	    file{"/etc/firewall/050-ntp.sh":
		    owner 	=> "root",
			group 	=> "root",
			mode 	=> "0550",
			ensure	=> present,
			content	=> template("kvmhost/tools/ntp.firewall.sh.erb"),
			require => File["/etc/firewall","/etc/ntp.conf"],
		}
	} else {
	    notify{"no firewall installed for ntp server":}
	}
}
