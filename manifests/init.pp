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
	$sysprefix		= 'kvm',

	# path infos
	$basepath		= '/srv/kvm',
	$etcpath		= '',
	$hdimagepath	= '',
	$cdrompath		= '',
	$defaultiso		= 'ubuntu-14.04.2-server-amd64.iso',
	$defaultisourl	= 'http://releases.ubuntu.com/14.04/ubuntu-14.04.2-server-amd64.iso',
	$piddir			= '',

	# networking
	$bridgename   	= 'kvmbr0',
	$localnet		= '192.168.0.0/16',

	$extif          = 'eth0',
	$defaultroutes	= [],
	$installntp		= true,

	$verbose		= false,

) {

  /* ---------------------------------------------
   * packages
   * --------------------------------------------- */

	kvmhost::tools::checkpackage { [
		"qemu-kvm",
		"uml-utilities","bridge-utils",
		"nfs-common","lvm2",
		"curl","postfix",
		"atop","vnstat" ]:
    		ensure => installed
  	}

  	case $lsbdistcodename {
    	'wheezy': {
      		kvmhost::tools::checkpackage{"kvm":
        		ensure => installed
      		}
    	}
    	'jessie': {
      		kvmhost::tools::checkpackage{"kvm":
        		ensure => installed
      		}
    	}    	
    	default: {
     		kvmhost::tools::checkpackage{"kvm-ipxe":
        		ensure => installed
      		}
    	}
  	}


  /* ---------------------------------------------
   * pathes
   * --------------------------------------------- */

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

 case $piddir {
   '': { $kvmhost_piddir = "/var/run/kvm" }
   default: { $kvmhost_piddir = $piddir }
 }

	File{
		owner   => "root",
		group   => "root",
	}

	# the base directory structure
	file { [
		"${kvmhost_basepath}/",
		"${kvmhost_basepath}/bin/",
		"${kvmhost_basepath}/bin/includes/",
		"${kvmhost_cdrompath}/",
		"${kvmhost_hdimagepath}/",
		"${kvmhost_etcpath}/",
		"${kvmhost_etcpath}/autostart/",
		"${kvmhost_piddir}/" ]:
		ensure => "directory",
		mode    => "0750",
	}

  	/* ---------------------------------------------
   	 * iso image
   	 * --------------------------------------------- */

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

  /* ---------------------------------------------
   * scripts
   * --------------------------------------------- */

	file { "${kvmhost_basepath}/bin/init.sh":
    	mode    => '0550',
    	content => template("kvmhost/init.sh.erb"),
	}

	file { "${kvmhost_basepath}/bin/ifup.sh":
		mode    => '0555',
		content => template("kvmhost/ifup.sh.erb"),
	}

	file { "${kvmhost_basepath}/bin/ifdown.sh":
		mode    => '0555',
		content => template("kvmhost/ifdown.sh.erb"),
	}

	file { "${kvmhost_basepath}/bin/includes/checkdrbd.sh.inc":
		mode    => '0440',
		content => template("kvmhost/includes/checkdrbd.sh.erb"),
		require => File["${kvmhost_basepath}/bin/includes/"],
	}

	file { "${kvmhost_basepath}/bin/includes/checkdisks.sh.inc":
		mode    => '0440',
		content => template("kvmhost/includes/checkdisks.sh.erb"),
		require => File["${kvmhost_basepath}/bin/includes/"],
	}

	file { "${kvmhost_basepath}/bin/includes/checkcdrom.sh.inc":
		mode    => '0440',
		content => template("kvmhost/includes/checkcdrom.sh.erb"),
		require => File["${kvmhost_basepath}/bin/includes/"],
	}

	file { "${kvmhost_basepath}/bin/includes/checknetwork.sh.inc":
	    mode    => '0440',
	    content => template("kvmhost/includes/checknetwork.sh.erb"),
	    require => File["${kvmhost_basepath}/bin/includes/"],
 	}

	file { "${kvmhost_basepath}/bin/includes/ifup-iptables.sh.inc":
		mode    => '0440',
		content => template("kvmhost/includes/ifup-iptables.sh.erb"),
		require => File["${kvmhost_basepath}/bin/includes/"],
	}

	file { "${kvmhost_basepath}/bin/includes/ifdown-iptables.sh.inc":
		mode    => '0440',
		content => template("kvmhost/includes/ifdown-iptables.sh.erb"),
		require => File["${kvmhost_basepath}/bin/includes/"],
	}

	/**
	 * synonmyes for init commands
	 */

	file { "${kvmhost_basepath}/bin/start.sh":
		mode    => '0550',
		content => template("kvmhost/start.sh.erb"),
		require => File["${kvmhost_basepath}/bin/"],
	}

	file { "${kvmhost_basepath}/bin/stop.sh":
		mode    => '0550',
		content => template("kvmhost/stop.sh.erb"),
	}

	file { "${kvmhost_basepath}/bin/killnode.sh":
		mode    => '0550',
		content => template("kvmhost/killnode.sh.erb"),
	}

	file { "/etc/init.d/kvmhost":
	    mode    => '0550',
	    content => template("kvmhost/kvmhost.init.erb"),
	    notify  => Exec["update-rc-kvmhost"],
	}

  	exec {"update-rc-kvmhost":
	    command => "/usr/sbin/update-rc.d kvmhost defaults",
	    require => File["/etc/init.d/kvmhost"],
	    refreshonly => true,
  	}
}
