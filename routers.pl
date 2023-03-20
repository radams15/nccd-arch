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
);

# Machine imports

our (
	$int_www,
	$int_dns,
	$ldap,
	$squid,
	$mail,
);


our $gw = Machine->new (
	name => 'gw',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '80.64.157.254',
		),
		Interface->new (
			eth => 1,
			ip => '192.168.0.1/24',
		),
	],
	routes => [
		Route->new (
			dst => '172.16.0.0/24',
			via => '192.168.0.2'
		),
		Route->new (
			dst => '10.0.0.0/20',
			via => '192.168.0.3'
		),
	],
	attachments => [
		Attachment->new (
			lan => $ext_www_lan,
			eth => 0
		),
		Attachment->new (
			lan => $dmz_lan,
			eth => 1
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		)
	],
);


our $r1 = Machine->new (
	name => 'r1',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '192.168.0.2/24',
		),
		Interface->new (
			eth => 1,
			ip => '172.16.0.1/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '192.168.0.1'
		),
		Route->new (
			dst => '10.0.0.0/20',
			via => '192.168.0.3'
		),
	],
	attachments => [
		Attachment->new (
			lan => $dmz_lan,
			eth => 0
		),
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 1
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		
		Rule->new (
			chain => 'FORWARD',
			proto => 'udp',
			dport => 53,
			dst => ($int_dns->ips)[0],
			src => '192.168.0.3',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 389,
			dst => ($ldap->ips)[0],
			src => '192.168.0.3',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			proto => 'udp',
			dport => 389,
			dst => ($ldap->ips)[0],
			src => '192.168.0.3',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 3129,
			dst => ($squid->ips)[0],
			src => '192.168.0.3',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 25,
			dst => ($mail->ips)[0],
			in => 'eth0',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 587,
			dst => ($mail->ips)[0],
			in => 'eth0',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 993,
			dst => ($mail->ips)[0],
			in => 'eth0',
			action => 'ACCEPT',
		),
	],
);

our $r2 = Machine->new (
	name => 'r2',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '192.168.0.3/24',
		),
		Interface->new (
			eth => 1,
			ip => '10.0.0.1/24',
		),
		Interface->new (
			eth => 2,
			ip => '10.0.1.1/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '192.168.0.1'
		),
		Route->new (
			dst => '172.16.0.0/24',
			via => '192.168.0.2'
		),
	],
	attachments => [
		Attachment->new (
			lan => $dmz_lan,
			eth => 0
		),
		Attachment->new (
			lan => $finance_lan,
			eth => 1
		),
		Attachment->new (
			lan => $hr_lan,
			eth => 2
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
		
		# Allow forwarding to internal dmz from eth1 and eth2
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			in => 'eth1',
			dst => '172.16.0.0/24',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			in => 'eth2',
			dst => '172.16.0.0/24',
			action => 'ACCEPT',
		),
		Rule->new (
			table => 'nat',
			chain => 'POSTROUTING',
			to_src => '192.168.0.3',
			action => 'SNAT',
		),
	],
);

1;
