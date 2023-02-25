#!/usr/bin/perl

use strict;
use warnings;

use Netkit::Machine;
use Netkit::Lan;
use Netkit::Lab;
use Netkit::Interface;
use Netkit::Route;
use Netkit::Attachment;
use Netkit::Rule;


require './staff.pl';
require './util.pl';



my $lab = Lab->new (
	name => 'TestLab',
	out_dir => 'res',
	data_dir => 'data',
);

####### LANs #######

my $ext_www_lan = Lan->new ('ExtWWW');
my $ext_office_lan = Lan->new ('ExtOffice');
my $ext_dns_lan = Lan->new ('ExtDns');
my $dmz_lan = Lan->new ('Dmz');
my $internal_dmz_lan = Lan->new ('InternalDmz');
my $staff_lan = Lan->new ('Staff');

####### Machines #######

my $gw = Machine->new (
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

# External

my $internet = Machine->new (
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
			lan => $dmz_lan,
			eth => 3
		),
	],
);

my $ext_dns = Machine->new (
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
	extra => "\nchmod +r /etc/dnsmasq_static_hosts.conf\nsystemctl start dnsmasq",
);

my $ext_www = Machine->new (
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
	extra => "\na2enmod ssl\na2ensite default-ssl\nsystemctl start apache2",
);


my $ext_office = Machine->new (
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


# Internal

my $int_dns = Machine->new (
	name => 'Int-DNS',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.3/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '172.16.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 0
		),
	],
	extra => "\nchmod +r /etc/dnsmasq_static_hosts.conf\nsystemctl start dnsmasq",
);

my $int_www = Machine->new (
	name => 'Int-WWW',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.2/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '172.16.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 0
		),
	],
	extra => "\na2enmod ssl\na2ensite default-ssl\nsystemctl start apache2",
);

my $ldap = Machine->new (
	name => 'LDAP',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.4/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '172.16.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 0
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@389\nsystemctl start ncat-udp-echo\@389",
);

my $mail = Machine->new (
	name => 'Mail',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.6/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '172.16.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 0
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@25\nsystemctl start ncat-tcp-broker\@587\nsystemctl start ncat-tcp-broker\@993",
);

my $squid = Machine->new (
	name => 'Squid',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '172.16.0.5/24',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '172.16.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $internal_dmz_lan,
			eth => 0
		),
	],
	extra => "\ntouch /var/log/squid/access.log\nchmod 777 /var/log/squid/access.log\nsystemctl start squid.service",
);


my $vpn = Machine->new (
	name => 'OpenVPN',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.0.0.2/20',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '10.0.0.1',
		),
	],
	attachments => [
		Attachment->new (
			lan => $staff_lan,
			eth => 0
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@1194",
);



my $staff_1 = &make_staff(1, $staff_lan);
my $staff_2 = &make_staff(2, $staff_lan);
my $staff_3 = &make_staff(3, $staff_lan);

# Routers

my $r1 = Machine->new (
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
			stateful => 1,
			proto => 'tcp',
			dport => 443,
			dst => ($int_www->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			proto => 'udp',
			dport => 53,
			dst => ($int_dns->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 389,
			dst => ($ldap->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			proto => 'udp',
			dport => 389,
			dst => ($ldap->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 3128,
			dst => ($squid->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 25,
			dst => ($mail->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 587,
			dst => ($mail->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
		Rule->new (
			chain => 'FORWARD',
			stateful => 1,
			proto => 'tcp',
			dport => 993,
			dst => ($mail->ips)[0],
			src => '10.0.0.0/20',
			action => 'ACCEPT',
		),
	],
);

my $r2 = Machine->new (
	name => 'r2',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '192.168.0.3/24',
		),
		Interface->new (
			eth => 1,
			ip => '10.0.0.1/20',
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
			lan => $staff_lan,
			eth => 1
		),
	],
	rules => [
		Rule->new (
			policy => 'FORWARD DROP',
		),
	],
);



####### Extra Configuration #######


dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);

$lab->dump(
	$gw,
	$internet,
	$ext_dns,
	$int_dns,
	$ext_www,
	$ext_office,
	$r1,
	$r2,
	$int_dns,
	$int_www,
	$ldap,
	$mail,
	$squid,
	$vpn,
	$staff_1,
	$staff_2,
	$staff_3,
);
