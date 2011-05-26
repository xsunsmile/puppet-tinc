
class tinc::inters {

  inters::executable::mongofile_put { "/etc/tinc/${name}/hosts/${fqdn_tinc}":
    require => File["/etc/tinc/${name}/hosts/${fqdn_tinc}"],
  }

}

