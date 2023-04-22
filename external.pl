#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

require './util.pl';

our $ext_www_lan;
our $ext_office_lan;
our $ext_dns_lan;
our $internet_connection_lan;

# External

our $internet = Machine->new (
	name => 'Internet',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '201.224.131.22/16',
		),
		Interface->new (
			eth => 1,
			ip => '8.8.8.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '22.39.224.17/30',
		),
		Interface->new (
			eth => 3,
			ip => '80.64.157.254/16',
		),
	],
	attachments => [
		Attachment->new (
			lan => $ext_www_lan,
			eth => 0
		),
		Attachment->new (
			lan => $ext_dns_lan,
			eth => 1
		),
		Attachment->new (
			lan => $ext_office_lan,
			eth => 2
		),
		Attachment->new (
			lan => $internet_connection_lan,
			eth => 3
		),
	],
);

our $ext_dns = Machine->new (
	name => 'Ext-DNS',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '8.8.8.8/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '8.8.8.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $ext_dns_lan,
			eth => 0
		),
	],
	extra => "\nchmod +r /etc/dnsmasq_static_hosts.conf\n/etc/init.d/dnsmasq start",
);

our $ext_www = Machine->new (
	name => 'Ext-WWW',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '201.224.19.7/16',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '201.224.131.22',
		),
	],
	attachments => [
		Attachment->new (
			lan => $ext_www_lan,
			eth => 0
		),
	],
	extra => "\na2enmod ssl\na2ensite default-ssl\n/etc/init.d/apache2 start",
);


our $ext_office = Machine->new (
	name => 'Ext-Office',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '22.39.224.18/30',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '22.39.224.17',
		),
	],
	attachments => [
		Attachment->new (
			lan => $ext_office_lan,
			eth => 0
		),
	],
);

1;
