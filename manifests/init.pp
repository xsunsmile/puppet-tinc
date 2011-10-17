# manifests/init.pp - module to manage tinc-vpn

class tinc {
	include bridge-utils

	case $operatingsystem {
		centos: { include tinc::centos }
		default: { include tinc::base }
	}

	if $use_shorewall {
		include shorewall::rules::tinc
	}

	$mongodb_host = extlookup('mongodb_host')

	cron { 'download-tinc-hosts':
		ensure => present,
		command => "/usr/bin/mongo_get ${mongodb_host} /etc/tinc || true",
		user => root,
		minute => '*/1',
	}

}
