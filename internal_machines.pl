#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

require './util.pl';

our (
	$ext_www_lan,
    $ext_office_lan,
    $ext_dns_lan,
    $dmz_lan,
    $internal_dmz_lan,
    $finance_lan,
    $hr_lan,
	$vpn_lan,
	
	$dmz_router,
    $internal_router,
    $internal_dmz_router,
);


# Internal

our $int_dns = Machine->new (
	name => 'Int-DNS',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.26.0.4/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{1}, # internal_router eth1
		),
	],
	extra => "
echo search_domains_append=fido22.cyber.test >> /etc/resolvconf.conf
chmod +r /etc/dnsmasq_static_hosts.conf
/etc/init.d/dnsmasq start",
);

our $int_www = Machine->new (
	name => 'Int-WWW',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.26.0.3/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{1}, # internal_router eth1
		),
	],
	extra => "\na2enmod ssl\na2ensite default-ssl\n/etc/init.d/apache2 start",
);

our $ldap = Machine->new (
	name => 'LDAP',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.36.0.2/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_dmz_router->ips->{1}, # internal_router eth1,
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@389\nsystemctl start ncat-udp-echo\@389",
);

our $mail = Machine->new (
	name => 'Mail',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.2/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $dmz_router->ips->{2}, # dmz_router eth2
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@25\nsystemctl start ncat-tcp-broker\@587\nsystemctl start ncat-tcp-broker\@993",
);

our $squid = Machine->new (
	name => 'Squid',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.26.0.2/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{1}, # internal_router eth1
		),
	],
	extra => "\ntouch /var/log/squid/access.log\nchmod 777 /var/log/squid/access.log\nchown -R proxy:proxy /var/log/squid/\n/etc/init.d/squid start",
);


our $vpn = Machine->new (
	name => 'OpenVPN',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.3/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{2}, # internal_router eth2,
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@1194",
);

our $staff_dhcp = Machine->new (
	name => 'StaffDhcp',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.6/16',
		),
		Interface->new (
			eth => 1,
			ip => '10.10.0.7/16',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{2}, # internal_router eth3
		),
	],
	attachments => [
		# eth0, eth1 -> staff_switch
	],
	extra => "\
/etc/init.d/isc-dhcp-server start
	",
);

1;
