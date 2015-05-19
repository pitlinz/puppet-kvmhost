define udm_hosts::tools::kvmnet (
  $remoteip = undef,
  $rhostid = undef
) {

  if $remoteip != $network_eth0 {
	  if $remoteip > $network_eth0 {
	    $localvip  = "192.168.2$rhostid.1"
	    $remotevip = "192.168.2$rhostid.2"
	  } else {
	    $localvip  = "192.168.2$rhostid.2"
	    $remotevip = "192.168.2$rhostid.1"
	  }

	  file {"/etc/firewall/300-init-$name.sh":
	    ensure  => present,
	    owner   => "root",
	    group   => "root",
	    mode    => "0550",
	    content => template("kvmhosts/firewall/init-vlan.sh.erb")
	  }
  }
}
