# A puppet module to configure a kvm host / guest firwall
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#
# requires puppet module install example42-network

define kvmhost::firewall(
  $ensure = present,
  $bridgeif = "br0",
  $bridgeip = undef,
  $hostid  = "00",
  $vlan_net = "192.168.0.0/16",
  $sshport = "2200",

  $extif   = "eth0"
) {

  file {"/etc/firewall":
    ensure => directory,
    owner   => "root",
    group   => "root",
    mode    => 0750,
  }

  file {"/etc/firewall/000-init.sh":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0550,
    content => template("kvmhost/firewall/init.sh.erb"),
  }
  
  file {"/etc/firewall/010-routing.sh":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0550,
    content => template("kvmhost/firewall/routing.sh.erb"),
  }  
  
  file {"/etc/init.d/kvmfirewall":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0550,
    content => template("kvmhost/firewall/kvmfirewall.erb"),
    require => File["/etc/firewall/000-init.sh","/etc/firewall/010-routing.sh"]
  }
  
  file {"/etc/rc2.d/S80-kvmfirewall":
    ensure => link,
    target => "/etc/init.d/kvmfirewall",
    require=> File['/etc/init.d/kvmfirewall']
  }

}
