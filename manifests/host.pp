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
 $dns_forwarders  = ['8.8.8.8','8.8.4.4'],
 $dns_allow_query = ['127.0.0.0/8', '192.168.0.0/16'],
 $dns_reverszone  = '',
 
 $configure_net  = true,  
 # eth0:   
 $eth0_usedhcp    = false,
 $eth0_ipv4       = $ipaddress_eth0,
 $eth0_netmask    = $netmask_eth0,
 $eth0_network    = $network_eth0,
 $eth0_broadcast  = '',
 $eth0_gateway    = '',
 
 # br0:
 $br0_name        = 'kvmbr0',
 $br0_ipv4        = '192.168.100.1',    
 $br0_netmask     = '255.255.255.0',
 $br0_network     = '192.168.100.0',
 $br0_broadcast   = '192.168.100.255',
 $br0_dhcpstart   = '192.168.100.010',
 $br0_dhcpend     = '192.168.100.099',

 #monit
 $monitchecks     = true,
 $monitdevices    = false,
 
 #guests
 $kvm_vgname      = 'kvm',
 $kvm_vgdevices   = false,
 $kvmguest_ippre  = '',
 $kvmguest_macpre = '',
 $kvmguests       = false,
 
) {
  
  package { [
      "kvm-ipxe", "qemu-kvm", 
      "uml-utilities","bridge-utils", 
      "nfs-common" ]:
    ensure => latest
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
	      up => [ "route add -net $eth0_network netmask $eth0_netmask gw $eth0_gateway eth0" ]
	    }
 	  }
  
	  network::interface { "$br0_name":
	    auto => true,
	    ipaddress => $br0_ipv4,
	    netmask => $br0_netmask,
	    network => $br0_network,
	    pre_up => [
	      "/sbin/brctl addbr ${br0_name}",
	      "echo 1 > /proc/sys/net/ipv4/ip_forward"
	    ],
	    post_down => [
	      "post-down /sbin/brctl delbr ${br0_name}"
	    ]
	  }
  }
      
  if $install_dnssrv {
	  include dns::server
	
	  dns::server::options {'/etc/bind/named.conf.options':
	    forwarders => $dns_forwarders,
	    allow_query => $dns_allow_query,
	    listen_on => [ $br0_ipv4 ],
	    listen_on_v6 => [],
	  }
	  
	  if !defined($global_dns_nameservers) {
	    $global_dns_nameservers = [ "${name}.${lan_domain}" ]
	  }  
	  
	  if (!defined($global_dns_soa) or ($global_dns_soa == '')) {   
	    $global_dns_soa = "${name}.${lan_domain}"
	  }
	  
	  
	  if $lan_domain != 'localnet' {
		  if !defined(::Dns::Zone[$lan_domain]) {	
			  dns::zone { "${lan_domain}":
			    soa => $global_dns_soa,
			    soa_email => "root.${lan_domain}",
			    nameservers => $global_dns_nameservers 
			  }  
	    }
	    
	    dns::record::a { "${name}":
	      zone  => $lan_domain,
	      data  => $br0_ipv4,
	      ptr   => true
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
	  }
	  
	  if $install_dhcpsrv {
		  include dhcp::server
	
		  dhcp::server::subnet { "${br0_network}":
		    netmask     => $br0_netmask,
		    routers     => $br0_ipv4,
		    broadcast   => $br0_broadcast,
		    range_begin => $br0_dhcpstart,
		    range_end   => $br0_dhcpend,
		    domain_name => $lan_domain,
		    dns_servers => [$br0_ipv4],     
		  }
    }
  }

  kvmhost::firewall { "fw_$name":
      hostid    => $hostid,
      bridgeif  => $br0_name,
      bridgeip  => $br0_ipv4,
  }

  kvmhost::drbd { "drbd_$name":

  }

  /* ---------------------------------------------------------
   * monit
   * --------------------------------------------------------- */  
  
  if $monitchecks and defined(Class['Monit']) {	  
    if $monitdevices {
      create_resources(monit::check::device,$monitdevices)        
    }  
    
    monit::predefined::checksshd { "sshd_${name}": 
      sshport => $sshport
    }
    
    monit::predefined::checkmdadm { "mdadm_${name}": }
    monit::predefined::checkdrbd { "mdadm_${name}": }
    
    monit::predefined::checkbind { "bind_${name}": 
      listenip => $br0_ipv4
    }
    monit::predefined::checkiscdhcp { "dhcp_${name}": }
  }
  
  /* ------------------------------------------------
   * guests
   * ------------------------------------------------ */

  if $kvm_vgdevices {
    lvm::volume_group { "${kvm_vgname}":
      physical_volumes => $kvm_vgdevices
    }
  }

  if $kvmguests {
    $kvmguestdefaults = {
      monitchecks     => $monitchecks,
      gateway         => $br0_ipv4,
      ippre           => $kvmguest_ippre,
      extip           => $eth0_ipv4,
      domain          => $lan_domain,      
    } 
    create_resources(kvmhost::host::guest,$kvmguests,$kvmguestdefaults) 
  }
}
