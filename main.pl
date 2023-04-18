#!/usr/bin/perl

use strict;
use warnings;

use Netkit;


my $STAFF_PER_DEPARTMENT = 1;


my $lab = Lab->new (
	name => 'TestLab',
	version => 0.7,
	author => 'Rhys Adams',
	out_dir => 'res',
	data_dir => 'data',
	shared => "resolvconf -u
systemctl start ssh",
);

####### LANs #######

our $ext_www_lan = Lan->new ('EXT_WWW');
our $ext_office_lan = Lan->new ('EXT_OFFICE');
our $ext_dns_lan = Lan->new ('EXT_DNS');
our $internet_connection_lan = Lan->new ('INTERNET');

our $internal_lan = Lan->new ('INTERNAL');
our $gateway_lan = Lan->new ('GATEWAY');
our $dmz_lan = Lan->new ('DMZ');
our $extranet_lan = Lan->new ('EXTRANET');
our $internal_dmz_lan = Lan->new ('INTERNAL_DMZ');
our $staff_lan = Lan->new ('STAFF');
our $finance_lan = Lan->new ('FINANCE');
our $hr_lan = Lan->new ('HR');
our $vpn_lan = Lan->new ('VPN');

####### VLANs #######

our $management_vlan = Vlan->new (4000);
our $dmz_vlan = Vlan->new(2000);
our $staff_vlan = Vlan->new (1000);
our $all_vlans = Vlan->new ('2-4095');

####### Machines #######

require './staff.pl';
require './util.pl';
require './external.pl';
require './routers.pl';
require './internal_machines.pl';

# Routers

our (
    $gw,
	$dmz_router,
    $internal_router,
    $internal_dmz_router,
    $hr_router,
    $finance_router,
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

# Switches

our $staff_switch = Machine->new (
	name => 'StaffSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..4),
	],
	attachments => [
		Attachment->new (lan  => $staff_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => 0,
);

our $dmz_switch = Machine->new (
	name => 'DmzSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..1),
	],
	attachments => [
		Attachment->new (lan  => $dmz_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => 0,
);

our $extranet_switch = Machine->new (
	name => 'ExtranetSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..3),
	],
	attachments => [
		Attachment->new (lan  => $extranet_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => 0,
);

our $internal_dmz_switch = Machine->new (
	name => 'InternalDmzSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..1),
	],
	attachments => [
		Attachment->new (lan  => $internal_dmz_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => 0,
);

####### Extra Configuration #######


# Machines to dump to the output folder.

my @switches = (
	$staff_switch,
	$dmz_switch,
	$extranet_switch,
	$internal_dmz_switch,
);

my @external_machines = (
	$internet,
	$ext_office,
	$ext_dns,
	$ext_www,
);

my @internal_machines = (
	$gw,
	$dmz_router,
    $internal_router,
    $internal_dmz_router,
    $hr_router,
    $finance_router,
	@switches,
	$int_dns,
	$int_www,
	$ldap,
	$mail,
	$squid,
	$vpn,
);

my @staff_machines = ();

# Add 3 HR machines.
for my $staff_id (1..$STAFF_PER_DEPARTMENT) {
	my $staff_machine = &make_staff('HR', $staff_id, $hr_lan, '10.20.0.%d/24');
	push @staff_machines, $staff_machine;
}

# Add 3 finance machines.
for my $staff_id (1..$STAFF_PER_DEPARTMENT) {
	my $staff_machine = &make_staff('Finance', $staff_id, $finance_lan, '10.30.0.%d/24');
	push @staff_machines, $staff_machine;
}

push @internal_machines, @staff_machines;

# Connect all the internal staff devices to the switch
switch_connect(
	switch => $staff_switch,
	start => 1,
	machines => [
		$internal_dmz_router,
		$vpn,
		$hr_router,
		$finance_router,
	]
);

switch_connect(
	switch => $dmz_switch,
	start => 1,
	machines => [
		$mail,
	]
);

switch_connect(
	switch => $extranet_switch,
	start => 1,
	machines => [
		$squid,
		$int_www,
		$int_dns,
	]
);

switch_connect(
	switch => $internal_dmz_switch,
	start => 1,
	machines => [
		$ldap,
	]
);

# Allow ICMP packets to be forwarded by all machines (for testing, remove for submission)
for my $machine (@internal_machines, @external_machines) {
	push @{$machine->{rules}}, Rule->new (
		chain => 'FORWARD',
		proto => 'icmp',
		action => 'ACCEPT',
	);
}

# DNAT mail ports from the gateway to the mailserver on the internal DMZ.
dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);

open HOSTS, '>', 'data/Int-DNS/etc/dnsmasq_static_hosts.conf';
for my $machine ($int_dns, $int_www, $ldap, $mail, $squid, $vpn) {
	
	for (grep {$_->{ip}} @{$machine->{interfaces}}) { # Every machine with an IP
		(my $ip = $_->{ip}) =~ s/\/\d+$//g; # Remove netmask
		print HOSTS "$ip";
	}

	print HOSTS "\t$machine->{name}.fido22.cyber.test\n";
}
close HOSTS;


#install_packages($lab, $mail, "dovecot-core libexttextcat-2.0-0 libexttextcat-data libsodium23 postfix");

$lab->dump(
	machines => [
		#@external_machines,
		@internal_machines,
	],
	deps => {
		
	}
);
