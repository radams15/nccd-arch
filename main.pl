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

our $ext_www_lan = Lan->new ('ExtWWW');
our $ext_office_lan = Lan->new ('ExtOffice');
our $ext_dns_lan = Lan->new ('ExtDns');
our $internet_connection_lan = Lan->new ('InternetConnection');
our $office_lan = Lan->new ('Office');
our $internal_dmz_lan = Lan->new ('InternalDmz');
our $finance_lan = Lan->new ('Finance');
our $hr_lan = Lan->new ('Hr');
our $it_lan = Lan->new ('It');
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

# Switches

our $a0 = Machine->new (
	name => 'a0',
	interfaces => [
		Interface->new (eth=>0, mac=>"08:00:4e:a0:a0:00"),
		map {
			Interface->new (eth=>$_, mac=>"08:00:4e:a0:a0:0$_");
		} (1..5),
	],
	attachments => [
		Attachment->new (lan  => $internal_dmz_lan, eth => 0)
	],
	switch => 1,
	vlan_filtering => 1,
	extra => "\nip link set dev sw0 address 08:00:4e:a0:a0:00\n",
);


####### Extra Configuration #######


# Machines to dump to the output folder.

my @external_machines = (
	$internet,
	$ext_office,
	$ext_dns,
	$ext_www,
);

my @internal_machines = (
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

my @staff_machines = ();
my @it_machines = ();

# Add 3 finance machines.
for my $staff_id (1..$STAFF_PER_DEPARTMENT) {
	my $staff_machine = &make_staff('Finance', $staff_id, $finance_lan, '10.0.1.%d/24');
	push @staff_machines, $staff_machine;
}

# Add 3 HR machines.
for my $staff_id (1..$STAFF_PER_DEPARTMENT) {
	my $staff_machine = &make_staff('HR', $staff_id, $hr_lan, '10.0.2.%d/24');
	push @staff_machines, $staff_machine;
}

for my $staff_id (1..$STAFF_PER_DEPARTMENT) {
	my $staff_machine = &make_staff('IT', $staff_id, $it_lan, '10.0.0.%d/24');
	push @it_machines, $staff_machine;
}

push @internal_machines, (@staff_machines, @it_machines);

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


# Add every interface on every router to the management VLAN.
for my $machine ($r1, $r2, $a0) {
	for my $interface (@{$machine->{interfaces}}) {
		push @{$machine->{attachments}}, Attachment->new (
			vlan => $management_vlan,
			eth=>$interface->{eth}
		);
	}
}

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
for my $machine ($int_dns, $int_www, $ldap, $mail, $squid, $vpn, @staff_machines) {
	
	for (grep {$_->{ip}} @{$machine->{interfaces}}) { # Every machine with an IP
		(my $ip = $_->{ip}) =~ s/\/\d+$//g; # Remove netmask
		print HOSTS "$ip";
	}

	print HOSTS "\t$machine->{name}.fido22.cyber.test\n";
}
close HOSTS;


#install_packages($lab, $mail, "dovecot-core libexttextcat-2.0-0 libexttextcat-data libsodium23 postfix");

$lab->dump(
	machines => [ @external_machines, @internal_machines ]
);
