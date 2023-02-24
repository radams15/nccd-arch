#!/usr/bin/perl

use strict;
use warnings;

use Netkit::Rule;

sub dnat {
	my %args = @_;
	my $dst = $args{dst};
	my $source = $args{src};
	my @ports = @{ $args{ports} };
	
	foreach my $port (@ports) {
		$source->rule(
			Rule->new (
				chain => 'FORWARD',
				stateful => 1,
				proto => 'tcp',
				dst => $dst,
				dport => $port,
				action => 'ACCEPT',
			)
		);
		
		$source->rule(
			Rule->new (
					table => 'nat',
					chain => 'PREROUTING',
					proto => 'tcp',
					to_dst => $dst,
					dport => $port,
					action => 'DNAT',
			)
		);
	}
}


1;
