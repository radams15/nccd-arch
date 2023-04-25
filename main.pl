#!/usr/bin/perl

use strict;
use warnings;

use Netkit;


my $STAFF_PER_DEPARTMENT = 1;

my $VLAN_FILTERING = 0;


my $lab = Lab->new (
	name => 'TestLab',
	version => 0.9,
	author => 'Rhys Adams',
	out_dir => 'res',
	data_dir => 'data',
	shared => "/etc/init.d/ssh start",
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
our $management_lan = Lan->new ('MANAGEMENT');
our $external_management_lan = Lan->new ('EXT_MANAGEMENT');

####### VLANs #######

our $management_vlan = Vlan->new (4000);
our $hr_vlan = Vlan->new (1000);
our $finance_vlan = Vlan->new (2000);
our $all_vlans = Vlan->new ('2-4094');

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
    $management_router,
);

# External

our (
    $internet,
    $ext_dns,
    $ext_www,
    $ext_office,
);

# Internal

our (
    $int_dns,
    $int_www,
    $ldap,
    $mail,
    $squid,
    $vpn,
    $management_a,
	$staff_dhcp,
);

# Switches

our $staff_switch = Machine->new (
	name => 'StaffSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..6),
	],
	attachments => [
		Attachment->new (lan  => $staff_lan, eth => 0, vlan => $all_vlans)
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
	disable_stp => 1,
	extra => '

'
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
	vlan_filtering => $VLAN_FILTERING,
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
	vlan_filtering => $VLAN_FILTERING,
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
	vlan_filtering => $VLAN_FILTERING,
);

our $internal_management_switch = Machine->new (
	name => 'InternalManagementSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..1),
	],
	attachments => [
		Attachment->new (lan  => $management_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $external_management_switch = Machine->new (
	name => 'ExternalManagementSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..6),
	],
	attachments => [
		Attachment->new (lan  => $external_management_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $finance_switch_a = Machine->new (
	name => 'FinanceSwitchA',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..$STAFF_PER_DEPARTMENT),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $hr_switch_a = Machine->new (
	name => 'HrSwitchA',
	interfaces => [
		map {
			Interface->new (
				eth=>$_,
			);
		} (0..$STAFF_PER_DEPARTMENT),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $finance_switch_b = Machine->new (
	name => 'FinanceSwitchB',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..$STAFF_PER_DEPARTMENT),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $hr_switch_b = Machine->new (
	name => 'HrSwitchB',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..$STAFF_PER_DEPARTMENT),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);


our $building_a_switch = Machine->new (
	name => 'BuildingASwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..2),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);

our $building_b_switch = Machine->new (
	name => 'BuildingBSwitch',
	interfaces => [
		map {
			Interface->new (eth=>$_);
		} (0..2),
	],
	switch => 1,
	vlan_filtering => $VLAN_FILTERING,
);


####### Extra Configuration #######


# Machines to dump to the output folder.

my @switches = (
	$staff_switch,
	$dmz_switch,
	$extranet_switch,
	$internal_dmz_switch,
	$hr_switch_a,
	$finance_switch_a,
	$hr_switch_b,
	$finance_switch_b,
	$building_a_switch,
	$building_b_switch,
);

my @routers = (
	$dmz_router,
    $internal_router,
    $internal_dmz_router,
);

my @external_machines = (
	$internet,
	$ext_office,
	$ext_dns,
	$ext_www,
);

my @internal_machines = (
	$gw,
	@routers,
	@switches,
	$int_dns,
	$int_www,
	$ldap,
	$mail,
	$squid,
	$vpn,
	$staff_dhcp,
);

my %deps;

sub get_staff {
	my ($num, $ref) = @_;
	my @machines;
	
	for my $staff_id (1..$num) {
		my $staff_machine = &make_staff($ref, $staff_id);
		$deps{$staff_machine->{name}} = [$staff_dhcp->{name}];
		push @machines, $staff_machine;
	}
	
	@machines;
}

my @hr_a_machines = &get_staff($STAFF_PER_DEPARTMENT, 'HR-A');
my @hr_b_machines = &get_staff($STAFF_PER_DEPARTMENT, 'HR-B');
my @finance_a_machines = &get_staff($STAFF_PER_DEPARTMENT, 'Finance-A');
my @finance_b_machines = &get_staff($STAFF_PER_DEPARTMENT, 'Finance-B');

push @internal_machines, (@hr_a_machines, @hr_b_machines, @finance_a_machines, @finance_b_machines);

# Connect all the internal staff devices to the switch
switch_connect(
	switch => $staff_switch,
	start => 1,
	machines => [
		$internal_dmz_router,
		$vpn,
		$building_a_switch,
		$building_b_switch,
		[$staff_dhcp, $hr_vlan, undef, 0],
		[$staff_dhcp, $finance_vlan, undef, 1],
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

switch_connect(
	switch => $hr_switch_a,
	start => 1,
	machines => [
		map {[$_, $hr_vlan, 1]} @hr_a_machines
	],
);

switch_connect(
	switch => $hr_switch_b,
	start => 1,
	machines => [
		map {[$_, $hr_vlan, 1]} @hr_b_machines
	],
);

switch_connect(
	switch => $finance_switch_a,
	start => 1,
	machines => [
		map {[$_, $finance_vlan, 1]} @finance_a_machines
	],
);


switch_connect(
	switch => $finance_switch_b,
	start => 1,
	machines => [
		map {[$_, $finance_vlan, 1]} @finance_b_machines
	],
);

=pod
switch_connect(
	switch => $building_a_switch,
	start => 1,
	machines => [
		[$hr_switch_a, $hr_vlan],
		[$finance_switch_a, $finance_vlan],
	],
);

switch_connect(
	switch => $building_b_switch,
	start => 1,
	machines => [
		[$hr_switch_b, $hr_vlan],
		[$finance_switch_b, $finance_vlan],
	],
);
=cut

switch_connect(
	switch => $building_a_switch,
	start => 1,
	machines => [$hr_switch_a, $finance_switch_a],
);

switch_connect(
	switch => $building_b_switch,
	start => 1,
	machines => [$hr_switch_b, $finance_switch_b],
);


# Allow ICMP packets to be forwarded by all machines (for testing, remove for submission)
for my $machine (@internal_machines, @external_machines) {
	push @{$machine->{rules}}, Rule->new (
		chain => 'FORWARD',
		proto => 'icmp',
		action => 'ACCEPT',
	);
}

=pod
# DNAT mail ports from the gateway to the mailserver on the internal DMZ.
dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);
=cut

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
		@external_machines,
		@internal_machines,
	],
	deps => \%deps,
	disable_firewalls => 1,
);
