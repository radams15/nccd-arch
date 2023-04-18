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
	
	],
);

our $hr_router = Machine->new (
	name => 'HrRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.4/24',
		),
		Interface->new (
			eth => 1,
			ip => '10.20.0.1/16',
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
			lan => $hr_lan,
			eth => 1,
		),
	],
	rules => [
		Rule->new (
			table => 'nat',
			chain => 'POSTROUTING',
			to_src => '10.10.0.4',
			action => 'SNAT',
		),
	],
);

our $finance_router = Machine->new (
	name => 'FinanceRouter',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.10.0.5/24',
		),
		Interface->new (
			eth => 1,
			ip => '10.30.0.1/16',
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
			lan => $finance_lan,
			eth => 1,
		),
	],
	rules => [
		Rule->new (
			table => 'nat',
			chain => 'POSTROUTING',
			to_src => '10.10.0.5',
			action => 'SNAT',
		),
	],
);

1;
