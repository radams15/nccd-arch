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


sub switch_connect {
	my %args = @_;
	my $switch = $args{switch};
	my $eth = $args{start};
	my @machines = @{ $args{machines} };
	
	for (@machines) {
		my $name = Attachment::generate_lan_name($switch, $_); # Generate a unique lan name.
		my $lan = Lan->new($name); # Make a new 2-device LAN.
		
		# Attach to both machine and the switch
		push @{$_->{attachments}}, Attachment->new (lan => $lan, eth => 0);
		push @{$switch->{attachments}}, Attachment->new (lan => $lan, eth => $eth);
		
		# Then use the next NIC
		$eth++;
	}
}

1;
