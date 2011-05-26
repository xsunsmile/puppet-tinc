
class tinc::firewall {

  if $use_shorewall {
    $real_shorewall_zone = $shorewall_zone ? {
      'absent' => 'loc',
      default => $shorewall_zone
    }
    shorewall::interface { "${real_tinc_bridge_interface}":
      zone    =>  "${real_shorewall_zone}",
      rfc1918 => true,
      options =>  'routeback,logmartians';
    }
  }

}
