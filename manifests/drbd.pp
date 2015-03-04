# A puppet module to configure a drbd for kvm host
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
#
# To set any of the following, simply set them as variables in your manifests
# before the class is included, for example:
#

class kvmhost::drbd {
  package { 'drbd':
	 ensure => present,
	 name => 'drbd8-utils',
	}

	exec { 'modprobe drbd':
			path => ['/bin/', '/sbin/'],
			unless => 'grep -qe \'^drbd \' /proc/modules',
  }
}

define kvmhost::drbdResource(
  $ensure     = present,
  $minor      = undef,
  $disk       = undef,
  $drbdMasterName = undef,
  $drbdMasterIp   = undef,
  $drbdSlaveName  = undef,
  $drbdSlaveIp    = undef
) {
  file {"/etc/drbd.d/$name.res":
    ensure  => $ensure,
    owner   => "root",
    group   => "root",
    mode    => 0550,
    content => template("kvmhost/drbd/resource.res.erb"),
  }
}

