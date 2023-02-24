#!/usr/bin/perl

use strict;
use warnings;

use Netkit::Machine;

sub make_staff {
	my ($id, $lan) = @_;
	
	my $last_ip_digit = 4 + $id;
	
	Machine->new (
		name => "Staff-$id",
		interfaces => [
			Interface->new (
				eth => 0,
				ip => "10.0.0.$last_ip_digit/20",
			),
		],
		routes => [
			Route->new (
				dst => 'default',
				via => '10.0.0.1'
			),
		],
		attachments => [
			Attachment->new (
				lan => $lan,
				eth => 0,
			),
		],
	);
}

1;
