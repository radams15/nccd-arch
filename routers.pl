#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

require './util.pl';

our (
	$ext_www_lan,
    $ext_office_lan,
    $ext_dns_lan,
    $internet_connection_lan,
    $dmz_lan,
    $gateway_lan,
    $internal_lan,
    $internal_dmz_lan,
    $staff_lan,
    $extranet_lan,
    $hr_lan,
    $finance_lan,
);

our $gw = Machine->new (
	name => 'gw',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '80.64.157.200',
		),
		Interface->new (
			eth => 1,
			ip => '192.168.0.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '192.168.2.6/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			dev => 'eth0', # Unsure if works
		),
	],
	attachments => [
		Attachment->new (
			lan => $internet_connection_lan,
			eth => 0,
		),
		Attachment->new (
			lan => $gateway_lan,
			eth => 1,
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		Rule->new ( # Allow forwarding port 80,443/tcp from proxy to web.
			stateful => 1,
			chain => 'FORWARD',
			proto => 'TCP',
			dport => [80,443],
			src => '172.26.0.2',
			out => 'eth0',
			action => 'ACCEPT',
		),
	],
);


our $dmz_router = Machine->new (
	name => 'DmzRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '192.168.0.2/24',
		),
		Interface->new (
			eth => 1,
			ip => '192.168.1.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '172.16.0.1/24',
		),
		Interface->new (
			eth => 3,
			ip => '192.168.2.7/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $gw->ips->{1},
		),
		Route->new (
			dst => '172.26.0.0/24',
			via => '192.168.1.2',
			dev => 'eth1',
		),
		Route->new (
			dst => '10.10.0.0/24',
			via => '192.168.1.2',
			dev => 'eth1',
		),
		Route->new (
			dst => '172.36.0.0/24',
			via => '192.168.1.2',
			dev => 'eth1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $gateway_lan,
			eth => 0,
		),
		Attachment->new (
			lan => $internal_lan,
			eth => 1,
		),
		Attachment->new (
			lan => $dmz_lan,
			eth => 2,
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		Rule->new ( # Allow forwarding port 80,443/tcp from proxy to gateway.
			stateful => 1,
			chain => 'FORWARD',
			proto => 'TCP',
			dport => [80,443],
			src => '172.26.0.2',
			out => 'eth0',
			action => 'ACCEPT',
		),
	],
);

our $internal_router = Machine->new (
	name => 'InternalRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '192.168.1.2/24',
		),
		Interface->new (
			eth => 1,
			ip => '172.26.0.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '10.10.0.1/24',
		),
		Interface->new (
			eth => 3,
			ip => '192.168.2.2/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $dmz_router->ips->{1}, # dmz_router eth1
		),
		Route->new (
			dst => '172.36.0.0/24', # Internal DMZ via InternalDmzRouter
			via => '10.10.0.2',
			dev => 'eth2',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_lan,
			eth => 0,
		),
		Attachment->new (
			lan => $extranet_lan,
			eth => 1,
		),
		Attachment->new (
			lan => $staff_lan,
			eth => 2,
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		Rule->new ( # Allow forwarding port 80,443/tcp from enterprise zone to proxy.
			stateful => 1,
			chain => 'FORWARD',
			proto => 'TCP',
			dport => '80,443',
			dst => '172.26.0.2',
			in => 'eth2',
			action => 'ACCEPT',
		),
		Rule->new ( # Allow forwarding port 53/udp from enterprise zone to IntDNS.
			stateful => 1,
			chain => 'FORWARD',
			proto => 'UDP',
			dport => '53',
			dst => '172.26.0.4',
			in => 'eth2',
			action => 'ACCEPT',
		),
		Rule->new ( # Allow forwarding port 25,587,993/tcp from enterprise zone to Mail.
			stateful => 1,
			chain => 'FORWARD',
			proto => 'TCP',
			dport => [25,587,993],
			dst => '172.16.0.2',
			in => 'eth2',
			action => 'ACCEPT',
		),
	],
);

our $internal_dmz_router = Machine->new (
	name => 'InternalDmzRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.2/24',
		),
		Interface->new (
			eth => 1,
			ip => '172.36.0.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '192.168.2.3/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{2}, # internal_router eth0
		),
	],
	attachments => [ # eth0 -> staff_switch
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 1,
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		Rule->new ( # Allow forwarding within internal DMZ zone.
			stateful => 1,
			chain => 'FORWARD',
			in => 'eth1',
			out => 'eth1',
			action => 'ACCEPT',
		),
		Rule->new ( # Allow forwarding port 389/tcp from enterprise zone.
			stateful => 1,
			chain => 'FORWARD',
			in => 'eth0',
			out => 'eth1',
			proto => 'TCP',
			dport => '389',
			action => 'ACCEPT',
		),
		Rule->new ( # Allow forwarding port 389/udp from enterprise zone.
			stateful => 1,
			chain => 'FORWARD',
			in => 'eth0',
			out => 'eth1',
			proto => 'UDP',
			dport => '389',
			action => 'ACCEPT',
		),
	],
);

our $management_router = Machine->new (
	name => 'ManagementRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.1.0.1/16',
		),
		Interface->new (
			eth => 1,
			ip => '192.168.2.1/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{3}, # internal_router eth3
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
	],
);


our $staff_dhcp = Machine->new ( # TODO: move to internal_machines as not a router.
	name => 'StaffDhcp',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.6/16',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => $internal_router->ips->{2}, # internal_router eth3
		),
	],
	attachments => [
		# eth0 -> staff_switch
	],
	extra => "\
/etc/init.d/isc-dhcp-server start
	",
);

1;
