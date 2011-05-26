
class tinc::bridge {

  $real_tinc_bridge_interface = $tinc_bridge_interface ? {
    'absent' => "br${name}",
    default => $tinc_bridge_interface
  }

  if $tinc_internal_ip == 'absent' {
    $tinc_br_ifaddr = "ipaddress_${real_tinc_bridge_interface}"
    $tinc_br_ip = inline_template("<%= scope.lookupvar(tinc_br_ifaddr) %>")
    case $tinc_br_ip {
      '',undef: {
        $tinc_orig_ifaddr = "ipaddress_${tinc_internal_interface}"
        $real_tinc_internal_ip = inline_template("<%= scope.lookupvar(tinc_orig_ifaddr) %>")
      }
      default: { $real_tinc_internal_ip = $tinc_br_ip }
    }
  } else {
    $real_tinc_internal_ip = $tinc_internal_ip
  }

}
