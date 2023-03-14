#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

sub make_staff {
	my ($designation, $id, $lan, $lan_mask) = @_;
	
	my $last_ip_digit = 4 + $id;
	
	Machine->new (
		name => "Staff-$designation-$id",
		interfaces => [
			Interface->new (
				eth => 0,
				ip => sprintf($lan_mask, $last_ip_digit),
			),
		],
		routes => [
			Route->new (
				dst => 'default',
				via => sprintf($lan_mask, 1)
			),
		],
		attachments => [
			Attachment->new (
				lan => $lan,
				eth => 0,
			),
		],
		extra => "\
cat > /etc/resolv.conf << EOF
nameserver 80.64.41.131
search fido22.cyber.test
EOF",
	);
}

1;
