# A puppet module to configure a kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#
# requires puppet module install example42-network

class kvmhost::host(
 $sysprefix       = 'kvm',
 $hostid          = '00',
 $sshport         = '2200',
 
 $install_dnssrv  = true,
 $install_dhcpsrv = true,
 $lan_domain      = 'localnet',
 $lan_name        = '',
 $dns_forwarders  = ['8.8.8.8','8.8.4.4'],
 $dns_allow_query = ['127.0.0.0/8', '192.0.0.0/8'],
 $dns_reverszone  = '',
 $dns_nameservers = ["8.8.8.8"],
 $dns_search      = 'network.tld', 
 
 $configure_net   = true, 
 $extif           = "eth0",

 # eth0:   
 $eth0_usedhcp    = false,
 $eth0_ipv4       = $ipaddress_eth0,
 $eth0_netmask    = $netmask_eth0,
 $eth0_network    = $network_eth0,
 $eth0_broadcast  = '',
 $eth0_gateway    = '',
 
 $eth0_aliases    = false,
 
 # br0:  
 $br_name        = 'kvmbr0',
 $br_ipv4        = '192.168.100.1',    
 $br_netmask     = '255.255.255.0',
 $br_network     = '192.168.100.0',
 $br_networksize = '24',
 $br_broadcast   = '192.168.100.255',
 $br_dhcpstart   = '192.168.100.010',
 $br_dhcpend     = '192.168.100.099',
 $br_dhcpdns     = '192.168.100.1',

 $configure_iptbl = true,

 #monit
 $monitchecks     = true,
 $monitdevices    = false,
 
 #guests
 $configure_drbd  = false,   
 $kvm_vgname      = 'kvm',
 $kvm_vgdevices   = false,
 $kvmguest_ippre  = '',
 $kvmguest_macpre = '',
 $kvmguests       = false,
 
) {
  
  package { [
      "qemu-kvm", 
      "uml-utilities","bridge-utils", 
      "nfs-common" ]:
    ensure => installed
  }
  case $lsbdistcodename {
    'wheezy': {
      package{"kvm":
        ensure => installed
      }
    }
    default: {
      package{"kvm-ipxe":
        ensure => installed
      }
    }
  }
  
  if !defined(Class["kvmhost"]) {
    class {"kvmhost":
    }
  }
  
  class {"kvmhost::host::initscripts":
    extif       => $extif,
    bridgename  => $br_name,
    localnet    => "${br_network}/${br_networksize}",
    require     => Class["kvmhost"],
  }  
  
  /* ---------------------------------------------------------
   * Networking
   * --------------------------------------------------------- */
  if $configure_net {
  
	  # disable notify to be able the check the result
		class { 'network':
		  config_file_notify => '',
		}
	  
	  # auto enable 'lo' with address 127.0.0.1
	  network::interface { 'lo':
	    auto => true,
	    ipaddress => "127.0.0.1"
	  }

	  # auto enable 'eth0' with facts and params if not uses dhcsp
	  if !$eth0_usedhcp {  
	    network::interface { 'eth0':
	      auto => true,
	      ipaddress   => $eth0_ipv4,
	      netmask     => $eth0_netmask,
	      network     => $eth0_network,
	      gateway     => $eth0_gateway,
	      up          => [ "route add -net $eth0_network netmask $eth0_netmask gw $eth0_gateway eth0" ],
        dns_search  => $dns_search,
        dns_nameservers => $dns_nameservers,	      
	    }
	    
	    if is_hash($eth0_aliases) {
	      $eth0_aliases_defaults = {
	        auto        => true,
          netmask     => $eth0_netmask,
          network     => $eth0_network,	        
	      }
	      create_resources(network::interface,$eth0_aliases,$eth0_aliases_defaults) 
	    }
 	  }
  
	  network::interface { "$br_name":
	    auto => true,
	    ipaddress => $br_ipv4,
	    netmask => $br_netmask,
	    network => $br_network,
	    pre_up => [
	      "/sbin/brctl addbr ${br_name}",
	      "echo 1 > /proc/sys/net/ipv4/ip_forward"
	    ],
	    post_down => [
	      "post-down /sbin/brctl delbr ${br_name}"
	    ]
	  }
  }
      
  if $install_dnssrv {
	  include dns::server
	
	  dns::server::options {'/etc/bind/named.conf.options':
	    forwarders => $dns_forwarders,
	    allow_query => $dns_allow_query,
	    listen_on => [ $br_ipv4 ],
	    listen_on_v6 => [],
	  }
	  
    if $lan_name == '' {
      $hostname = "host-${hostid}"
    } else {
      $hostname = $lan_name
    }	  
	  
	  if !defined($global_dns_nameservers) {
	    $global_dns_nameservers = [ "${hostname}.${lan_domain}" ]
	  }  
	  
	  if (!defined($global_dns_soa) or ($global_dns_soa == '')) {   
	    $global_dns_soa = "${hostname}.${lan_domain}"
	  }
	  
	  
	  if $lan_domain != 'localnet' {
		  if !defined(::Dns::Zone[$lan_domain]) {	
			  dns::zone { "${lan_domain}":
			    soa => $global_dns_soa,
			    soa_email => "root.${lan_domain}",
			    nameservers => $global_dns_nameservers 
			  }  
	    }	   
	  }
	  
	  if $dns_reverszone != '' {
	    if !defined(::Dns::Zone[ "${dns_reverszone}" ]) { 
	      dns::zone { "${dns_reverszone}":
	        soa => $global_dns_soa,
	        soa_email => "root.${global_dns_soa}",
	        nameservers => $global_dns_nameservers          
	      }
	    }   
	    $dns_a_ptr = true
	  } else {
	    notify{"no dns_reversezone set":}
	    $dns_a_ptr = false 
	  }
	 	  
    dns::record::a { "${hostname}":
      zone  => $lan_domain,
      data  => $br_ipv4,
      ptr   => $dns_a_ptr
    }	  
	  
	  if $install_dhcpsrv {
	    class {"dhcp::server":
        interfaces => $br_name	      
	    }
	
		  dhcp::server::subnet { "${br_network}":
		    netmask     => $br_netmask,
		    routers     => $br_ipv4,
		    broadcast   => $br_broadcast,
		    range_begin => $br_dhcpstart,
		    range_end   => $br_dhcpend,
		    domain_name => $lan_domain,
		    dns_servers => $br_dhcpdns,     
		  }
    }
  }

  if $configure_iptbl and !defined(Kvmhost::Firewall["fw_$name"]) {
	  kvmhost::firewall { "fw_$name":
	      hostid    => $hostid,
	      bridgeif  => $br_name,
	      bridgeip  => $br_ipv4,
	  }
  }
	 

  /* ---------------------------------------------------------
   * monit
   * --------------------------------------------------------- */  
  
  if $monitchecks  {	  
    
    if defined(Class['Monit']) {
	    if $monitdevices and is_hash($monitdevices) {
	      create_resources(monit::check::device,$monitdevices)        
	    }  
	    
	    monit::predefined::checksshd { "sshd_${name}": 
	      sshport => $sshport
	    }
	    
	    monit::predefined::checkmdadm { "mdadm_${name}": }
	    monit::predefined::checkdrbd { "mdadm_${name}": }
	    
	    monit::predefined::checkbind { "bind_${name}": 
	      listenip => $br_ipv4
	    }
	    monit::predefined::checkiscdhcp { "dhcp_${name}": }
    } else {
      notify{"class monit not definde":}
    }
  }
  
  /* ------------------------------------------------
   * guests
   * ------------------------------------------------ */

  if $configure_drbd {
	  # @todo drbd
	  class {"kvmhost::drbd": }
  }
  
  if $kvm_vgdevices {
    lvm::volume_group { "${kvm_vgname}":
      physical_volumes => $kvm_vgdevices
    }
  }

  if $kvmguests and is_hash($kvmguests) {
    $kvmguestdefaults = {
      monitchecks     => $monitchecks,
      gateway         => $br_ipv4,
      ippre           => $kvmguest_ippre,
      extip           => $eth0_ipv4,
      domain          => $lan_domain,      
    } 
    create_resources(kvmhost::host::guest,$kvmguests,$kvmguestdefaults) 
  }
}
