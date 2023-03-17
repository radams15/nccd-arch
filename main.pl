#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

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
my $finance_lan = Lan->new ('Finance');
my $hr_lan = Lan->new ('Hr');

####### VLANs #######

my $management_vlan = Vlan->new (111);
my $int_dns_vlan = Vlan->new (222);
my $int_www_vlan = Vlan->new (333);
my $ldap_vlan = Vlan->new (444);
my $proxy_vlan = Vlan->new (555);
my $mail_vlan = Vlan->new (666);

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
			lan => $finance_lan,
			eth => 0
		),
	],
	extra => "\nsystemctl start ncat-tcp-broker\@1194",
);

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
			src => 'eth0',
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
	],
);


my $a0 = Machine->new (
	name => 'a0',
	interfaces => [
		Interface->new(eth=>0, mac=>"08:00:4e:a0:a0:00"),
		map {
			Interface->new(eth=>$_, mac=>"08:00:4e:a0:a0:0$_");
		} (1..5),
	],
	attachments => [
		Attachment->new (lan => $internal_dmz_lan, eth => 0),
	],
	switch => 1,
	extra => "\nip link set dev sw0 address 08:00:4e:a0:a0:00\n"
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



# Add 3 finance machines.
for my $staff_id (1..3) {
	my $staff_machine = &make_staff('Finance', $staff_id, $finance_lan, '10.0.0.%d/24');
	push @internal_machines, $staff_machine;
}

# Add 3 HR machines.
for my $staff_id (1..3) {
	my $staff_machine = &make_staff('HR', $staff_id, $hr_lan, '10.0.1.%d/24');
	push @internal_machines, $staff_machine;
}



# Associate r1 with every vlan in the internal DMZ.
for my $vlan ($int_www_vlan, $int_dns_vlan, $ldap_vlan, $proxy_vlan, $mail_vlan) { 
	push @{$r1->{attachments}}, Attachment->new ( vlan => $vlan, eth=>1 );
}


# Connect all the internal DMZ devices to the switch
switch_connect(
	switch => $a0,
	start => 1,
	machines => [$int_dns, $int_www, $ldap, $mail, $squid]
);


# Add every interface on every internal machine to the management VLAN.
for my $machine (@internal_machines) {
	for my $interface (@{$machine->{interfaces}}) {
		push @{$machine->{attachments}}, Attachment->new ( vlan => $management_vlan, eth=>$interface->{eth} );
	}
}


# DNAT mail ports from the gateway to the mailserver on the internal DMZ.
dnat (
	src => $gw,
	dst =>'172.16.0.6',
	ports => [25, 587, 993]
);

$lab->dump(@external_machines, @internal_machines);
