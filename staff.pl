#!/usr/bin/perl

use strict;
use warnings;

use Netkit;

sub make_staff {
	my ($designation, $id, $lan, $lan_mask) = @_;
	
	my $last_ip_digit = 4 + $id;
	
	my $default_route = sprintf($lan_mask, 1);
	$default_route =~ s/\/\d+$//g;
	
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
				via => $default_route
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
EOF

cat >> /root/.bashrc << EOF
export http_proxy='172.16.0.5:3129'
export https_proxy='172.16.0.5:3129'
EOF
",
	);
}

1;
