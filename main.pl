#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

my $STAFF_PER_DEPARTMENT = 1;


our $lab = Lab->new (
	name => 'TestLab',
	out_dir => 'res',
	data_dir => 'data',
);

####### LANs #######

our $ext_www_lan = Lan->new ('ExtWWW');
our $ext_office_lan = Lan->new ('ExtOffice');
our $ext_dns_lan = Lan->new ('ExtDns');
our $dmz_lan = Lan->new ('Dmz');
our $internal_dmz_lan = Lan->new ('InternalDmz');
our $finance_lan = Lan->new ('Finance');
our $hr_lan = Lan->new ('Hr');

####### VLANs #######

our $management_vlan = Vlan->new (111);
our $int_dns_vlan = Vlan->new (222);
our $int_www_vlan = Vlan->new (333);
our $ldap_vlan = Vlan->new (444);
our $proxy_vlan = Vlan->new (555);
our $mail_vlan = Vlan->new (666);

####### Machines #######

require './staff.pl';
require './util.pl';
require './external.pl';
require './internal_machines.pl';
require './routers.pl';

# Routers

our (
    $gw,
	$r1,
    $r2,
);

# External

our (
    $internet,
    $ext_dns,
    $ext_www,
    $ext_office,
);

our (
    $int_dns,
    $int_www,
    $ldap,
    $mail,
    $squid,
    $vpn
);


our $a0 = Machine->new (
	name => 'a0',
	interfaces => [
		Interface->new(eth=>0, mac=>"08:00:4e:a0:a0:00"),
		map {
			Interface->new(eth=>$_, mac=>"08:00:4e:a0:a0:0$_");
		} (1..5),
	],
	attachments => [
		Attachment->new (lan  => $internal_dmz_lan, eth => 0),
		Attachment->new (vlan => $int_www_vlan, eth => 1),
		Attachment->new (vlan => $int_dns_vlan, eth => 2),
		Attachment->new (vlan => $ldap_vlan, eth => 3),
		Attachment->new (vlan => $proxy_vlan, eth => 4),
		Attachment->new (vlan => $mail_vlan, eth => 5),
	],
	switch => 1,
	extra => "\nip link set dev sw0 address 08:00:4e:a0:a0:00\n",
);


####### Extra Configuration #######


# Machines to dump to the output folder.

our @external_machines = (
	$internet,
	$ext_office,
	$ext_dns,
	$ext_www,
);

our @internal_machines = (
	$gw,
	$a0,
	$r1,
	$r2,
	$int_dns,
	$int_www,
	$ldap,
	$mail,
	$squid,
	$vpn,
);

# Add 3 finance machines.
for our $staff_id (1..$STAFF_PER_DEPARTMENT) {
	our $staff_machine = &make_staff('Finance', $staff_id, $finance_lan, '10.0.0.%d/24');
	push @internal_machines, $staff_machine;
}

# Add 3 HR machines.
for our $staff_id (1..$STAFF_PER_DEPARTMENT) {
	our $staff_machine = &make_staff('HR', $staff_id, $hr_lan, '10.0.1.%d/24');
	push @internal_machines, $staff_machine;
}


# Connect all the internal DMZ devices to the switch
switch_connect(
	switch => $a0,
	start => 1,
	machines => [
		$int_www,
		$int_dns,
		$ldap,
		$squid,
		$mail,
	]
);


# Add every interface on every internal machine to the management VLAN.
for our $machine (@internal_machines) {
	for our $interface (@{$machine->{interfaces}}) {
		push @{$machine->{attachments}}, Attachment->new ( vlan => $management_vlan, eth=>$interface->{eth});
	}
}


# DNAT mail ports from the gateway to the mailserver on the internal DMZ.
dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);

$lab->dump(
	machines => [ @external_machines, @internal_machines ]
);
