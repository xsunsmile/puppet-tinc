
define tinc::vpn_net(
  $ensure = present,
  $hosts_path = 'absent',
  $connect_on_boot = true,
  $key_source_path = 'absent',
  $tinc_interface = 'eth0',
  $tinc_internal_interface = 'eth1',
  $tinc_internal_ip = 'absent',
  $tinc_bridge_interface = 'absent',
  $port = '655',
  $compression = '9',
  $shorewall_zone = 'absent'
){
  include ::tinc
  include tinc::inters

  # needed in template tinc.conf.erb
  $fqdn_tinc = regsubst("${fqdn}",'[._-]+','','G')

  file{"/etc/tinc/${name}":
    require => Package['tinc'],
    notify => Service['tinc'],
    owner => puppet, group => puppet, mode => 0664;
  }

  line{"tinc_boot_net_${name}":
    ensure => $ensure ? {
      'present' => $connect_on_boot ? {
        true => 'present',
        default => 'absent'
      },
      default => 'absent'
    },
    line => $name,
    file => '/etc/tinc/nets.boot',
    require => File['/etc/tinc/nets.boot'],
    notify => Service['tinc'],
  }

  $real_hosts_path = $hosts_path ? {
    'absent' => "/etc/tinc/${name}/hosts.list",
    default => $hosts_path
  }

  file { "/etc/tinc/${name}/hosts/${fqdn_tinc}":
    ensure => $ensure,
    notify => Service[tinc],
    tag => "tinc_host_${name}",
    owner => root, group => puppet, mode => 0660;
  }

  inters::functions::mongofile_put { "/etc/tinc/${name}/hosts/${fqdn_tinc}":
    require => File["/etc/tinc/${name}/hosts/${fqdn_tinc}"],
  }

  line{ "${fqdn_tinc}_for_${name}":
    ensure => $ensure,
    file => $real_hosts_path,
    line => $fqdn_tinc,
    tag => 'tinc_hosts_file'
  }

  if $ensure == 'present' {
    File["/etc/tinc/${name}"]{
      ensure => directory,
    }

    file{ "/etc/tinc/${name}/hosts":
      source => 'puppet:///modules/common/empty',
      ensure => directory,
      recurse => true,
      purge => true,
      force => true,
      require => Package['tinc'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0600;
    }

    $tinc_hosts_list = tfile($real_hosts_path)
    $tinc_all_hosts = split($tinc_hosts_list,"\n")
    $tinc_hosts = array_del($tinc_all_hosts,$fqdn_tinc)

    file { "/etc/tinc/${name}/tinc.conf":
      content => template('tinc/tinc.conf.erb'),
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }

    if $key_source_path == 'absent' {
      fail("You need to set \$key_source_prefix for $name to generate keys on the master!")
    }

    $tinc_keys = tinc_keygen($name,"${key_source_path}/${name}/${fqdn}")

    file{ "/etc/tinc/${name}/rsa_key.priv":
      content => $tinc_keys[0],
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }

    file{ "/etc/tinc/${name}/rsa_key.pub":
      content => $tinc_keys[1],
      notify => Service[tinc],
      owner => root, group => 0, mode => 0600;
    }

    file { "/etc/tinc/${name}/tinc-up":
      content => template('tinc/tinc-up.erb'),
      require => Package['bridge-utils'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0700;
    }

    file { "/etc/tinc/${name}/tinc-down":
      content => template('tinc/tinc-down.erb'),
      require => Package['bridge-utils'],
      notify => Service['tinc'],
      owner => root, group => 0, mode => 0700;
    }

    File["/etc/tinc/${name}/hosts/${fqdn_tinc}"]{
      content => template('tinc/host.erb'),
    }

    File<<| tag == "tinc_host_${name}" |>>

  } else {
    File["/etc/tinc/${name}"]{
      ensure => absent,
      recurse => true,
      purge => true,
      force => true
    }
  }
}
