#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

sub make_staff {
	my ($designation, $id) = @_;

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
export http_proxy='squid:3129'
export https_proxy='squid:3129'
EOF

sleep 10
dhclient&",
	);
}


1;
