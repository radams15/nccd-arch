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
my $dmz_lan = Lan->new ('Dmz');
my $internal_dmz_lan = Lan->new ('InternalDmz');
my $staff_lan = Lan->new ('Staff');

####### Machines #######

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

my $staff_1 = &make_staff(1, $staff_lan);
my $staff_2 = &make_staff(2, $staff_lan);
my $staff_3 = &make_staff(3, $staff_lan);



####### Extra Configuration #######


dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);

$lab->dump(
	$gw,
	$r1,
	$r2,
	$staff_1,
	$staff_2,
	$staff_3,
);
