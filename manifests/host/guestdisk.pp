/*
 * class kvmhost::host::guestdisk
 * 
 * configure a virtual server
 */
define kvmhost::host::guestdisk (
  $lvm      = undef,
  $drbd     = undef,
  $hostname = undef,
) {
  # notify{"creating guest disk: ${namepre}_${name} ${lvm[size]}": }
  
  if is_hash($lvm) {
	  case $lvm[ensure] {
	    '': { $lvm_ensure = present}
	    default: {$lvm_ensure = $lvm[ensure]}
	  }
	      
	  logical_volume { $name:
	    ensure       => $lvm_ensure,
	    volume_group => "${lvm[volume_group]}",
	    size         => "${lvm[size]}",
	  }  
  }
  
  if is_hash($drbd) {
    if $drbd[lvm] {
      $drbddisk = "${lvm[volume_group]}"
    } else {
      $drbddisk = $drbd[disk]
    }
    
    kvmhost::drbdResource{ $name:
        minor           => $drbd[minor],
        disk            => $drbddisk,
        drbdMasterName  => $drbd[drbdMasterName],
        drbdMasterIp    => $drbd[drbdMasterIp],
        drbdSlaveName   => $drbd[drbdSlaveName],
        drbdSlaveIp     => $drbd[drbdSlaveIp]      
    }
  }

}