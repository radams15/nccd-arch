#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

sub make_staff {
	my ($designation, $id, $lan_mask) = @_;
	
	my $last_ip_digit = 4 + $id;
	
	Machine->new (
		name => "Staff-$designation-$id",
		interfaces => [
			Interface->new (
				eth => 0,
			),
		],
		extra => "\
cat > /etc/resolv.conf << EOF
nameserver 172.26.0.4
search fido22.cyber.test
EOF

cat >> /root/.bashrc << EOF
export http_proxy='172.26.0.2:3129'
export https_proxy='172.26.0.2:3129'
EOF

dhclient&",
	);
}

our $management_a = Machine->new (
	name => 'ManagementA',
	interfaces => [
		Interface->new (
			eth => 0,
			ip => '10.1.0.2/16',
		),
	],
	routes => [
		Route->new (
			dst => 'default',
			via => '10.1.0.1', # internal_router eth0
		),
	],
);
1;
