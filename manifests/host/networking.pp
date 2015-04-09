/**
 * configure the network of a host
 *
 * implemented as class to be able to change some
 * settings in forman
 *
 */
class kvmhost::host::networking(
  $disablenotify	= true,		 # disable notify to be able the check the result

 # eth0:
 $eth0_usedhcp    = false,
 $eth0_ipv4       = $ipaddress_eth0,
 $eth0_netmask    = $netmask_eth0,
 $eth0_network    = $network_eth0,
 $eth0_broadcast  = '',
 $eth0_gateway    = '',

) {
  if $disablenotify {
	class { 'network':
	  config_file_notify => '',
	}
  } else {
	class { 'network':
	}
  }



}
