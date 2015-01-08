/*
 * class kvmhost::host::guestdisk
 * 
 * configure a virtual server
 */
define kvmhost::host::guestdisk (
  $lvm      = null,
  $drbd     = null,
  $hostname = null,
) {
  # notify{"creating guest disk: ${namepre}_${name} ${lvm[size]}": }
  
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