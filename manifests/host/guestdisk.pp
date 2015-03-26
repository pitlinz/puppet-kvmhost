/*
 * class kvmhost::host::guestdisk
 *
 * configure a virtual server
 */
define kvmhost::host::guestdisk (
  $ensure	= present,
  $file		= undef,
  $lvm      = undef,
  $drbd     = undef,
  $hostname = undef,
) {
  # notify{"creating guest disk: ${namepre}_${name} ${lvm[size]}": }

	if is_hash($file) {
    	if $ensure == present {

    	} elsif $ensure == absent {
    	  file{$file[$name]:
    	    ensure => $ensure
    	  }
    	}
	} elsif is_hash($lvm) {
 		logical_volume { $name:
 		  	ensure		 => $ensure,
	    	volume_group => "${lvm[volume_group]}",
	    	size         => "${lvm[size]}",
 		}
	}

}
