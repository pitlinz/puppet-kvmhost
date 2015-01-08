/*
 * class kvmhost::host::guest
 * 
 * configure a virtual server
 */
define kvmhost::host::guest (
  $guestid      = null,
  $ippre        = "192.168.0",
  $macpre       = "72:3c:78:fd:00",
  $extip        = "",
  $intip        = "",
  $gateway      = "192.168.0.1",
    
  $memory       = "512",
  $cpus         = "1",
  $disks        = {},
  $diskoptions  = [],

  $monitchecks  = true,
    
  $domain       = "localnet",
  $config_dhcp  = true,
  
  $fwnat        = [],
  $fwfilter     = [],
  
  $isoimage = "ubuntu-14.04.1-server-amd64.iso"
  
) {  
  $myip = "${ippre}.${guestid}"
  
  notify{"creating guest: ${name} ${myip}": }
  
  $diskdefaults = {
    hostname => $name,
  }
  create_resources(kvmhost::host::guestdisk,$disks,$diskdefaults)
    
  case $intip {
    '': { $guest_intip = "${ippre}.${guestid}" }
    default: { $guest_intip = "${intip}" }    
  }
    
  kvmhost::guest {"${name}":
    vncid         => "${guestid}",
    guestintip    => "${guest_intip}",
    guestmacaddr  => "${macpre}:${guestid}",
    guestextip    => $extip,
    guestcpus     => $cpus,
    guestmemory   => $memory,
    guestdisks    => $diskoptions,
    fwnat         => $fwnat,
    fwfilter      => $fwfilter,
    isoimage      => $isoimage
  }
  
  if $config_dhcp {
	  dhcp::server::host {"${name}":
	      address   => "$guest_intip",
	      hwaddress => "${macpre}:${guestid}",
	  }
  }
  
  if $domain != 'localnet' {
    dns::record::a { "${name}":
      zone  => $domain,
      data  => "${ippre}.${guestid}",
      ptr   => true
    }    
  } 
  
  
}
  