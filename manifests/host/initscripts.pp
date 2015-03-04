/*
 * class kvmhost::host::initscripts
 * 
 * create init scripts to start kvm hosts
 * 
 */
 
class kvmhost::host::initscripts (
  $kvmhost_basepath = $::kvmhost::kvmhost_basepath,
  $kvmhost_etcpath  = $::kvmhost::kvmhost_etcpath,
  $kvmhost_piddir   = $::kvmhost::kvmhost_piddir,
  
  $extif            = "eth0",
  $bridgename       = $::kvmhost::kvmhost_brigename,
  $localnet         = "192.168.0.0/16",

) {
  
  file { "${kvmhost_basepath}/bin/init.sh":
    owner   => "root",
    group   => "root",
    mode    => '0550',
    content => template("kvmhost/init.sh.erb"),
  }  
  
  file { "${kvmhost_basepath}/bin/ifup.sh":
    owner   => "root",
    group   => "root",
    mode    => '0555',
    content => template("kvmhost/ifup.sh.erb"),
  }

  file { "${kvmhost_basepath}/bin/ifdown.sh":
    owner   => "root",
    group   => "root",
    mode    => '0555',
    content => template("kvmhost/ifdown.sh.erb"),
  }  
  
}