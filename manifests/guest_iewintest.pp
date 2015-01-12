# A puppet module to configure a kvm host to run windows for ie testing
#
# get zipsource from: https://www.modern.ie/de-de/virtualization-tools
# @see https://gist.github.com/magnetikonline/5274656 
#
# author pitlinz@sourceforge.net
# (c) 2014 by w4c.at
#
# params:
# - name the image dir name
#
define kvmhost::guest_iewintest(
  $zipsource = false,
  
  $ensure       = present,  
  $vncid        = "",
  $autostart    = "0",
  $guestcpus    = "1",
  $guestmemory  = "1024",

  #network params    
  $guestintip     = undef,
  $guestmacaddr   = undef,
  $guestextip     = undef,
  $fwnat          = [],
  $fwfilter       = [],
  $config_dhcp    = true,
  
  # alternativ disk param method
  $guest_hdb    = false,
  $guest_hdc    = false,
  $guest_hdd    = false,

  
  # dnsMadeEasy setting
  $dnsMadeEasyId = false,
  $dnsMadeEasyUser = false,
  $dnsMadeEasyPasswd = false,
  $dnsMadeEasyUrl = "http://www.dnsmadeeasy.com/servlet/updateip",
) {
  
  if !$zipsource {
    notify{"no zip source for kvmhost::guest_iewintest ${name}":} 
  } else {
    
    $image_path = "${::kvmhost::kvmhost_hdimagepath}/${name}"
    
    
	  file {"${image_path}":
	    ensure => directory,
	    require => File["$::kvmhost::kvmhost_hdimagepath"]
	  }
  
    exec {"wget_${name}":
      command => "/usr/bin/wget -O ${name}.zip ${zipsource}",
      cwd     => "${image_path}",
      creates => "${image_path}/${name}.zip",
      require => File["${image_path}"]
    }
    
    
    if !defined(Package["unzip"]) {
      package{"unzip":
        ensure => installed
      }
    }
            
    file {"${image_path}/make_image.sh":
      ensure  => present,
      owner   => "root",
      group   => "root",
      mode    => "0550",
      content => template('kvmhost/guest/make_iewindisk.erb'),
      require => File["${image_path}"]      
    }
    
    exec {"make_image_${name}":
      command => "${image_path}/make_image.sh",
      cwd     => "${image_path}",
      creates => "${image_path}/${name}.qcow2"          
    }
    
    kvmhost::guest{"${name}":
        ensure      => $ensure,
        vncid       => $vncid,
        autostart   => $autostart,
        guestcpus   => $guestcpus,
        guestmemory => $guestmemory,
        
        guestintip    => $guestintip,
        guestmacaddr  => $guestmacaddr,
        guestextip    => $guestextip,
        fwnat         => $fwnat,
        fwfilter      => $fwfilter, 
        config_dhcp   => $config_dhcp,
        
        guest_hda     => "${image_path}/${name}.qcow2",
        guest_hdb     => $guest_hdb,
        guest_hdc     => $guest_hdc,
        guest_hdd     => $guest_hdd,
        isoimage      => false,
        
        dnsMadeEasyId     => $dnsMadeEasyId,
        dnsMadeEasyUser   => $dnsMadeEasyUser,
        dnsMadeEasyPasswd => $dnsMadeEasyPasswd,
        dnsMadeEasyUrl    => $dnsMadeEasyUrl,              
    }
  
  }
  


}