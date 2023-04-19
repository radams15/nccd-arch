#!/usr/bin/perl

use strict;
use warnings;

use Cwd;

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
	my $machines = $args{machines};
	
	if(ref $machines eq 'ARRAY') {
		for (@$machines) {
			my ($machine, $machine_eth);
			if(ref $_ eq 'ARRAY') {
				($machine, $machine_eth) = @$_;
			}else {
				$machine = $_;
				$machine_eth = 0;
			}
			
			my $name = Attachment::generate_lan_name($switch, $machine); # Generate a unique lan name.
			my $lan = Lan->new($name); # Make a new 2-device LAN.
			
			# Attach to both machine and the switch
			push @{$machine->{attachments}}, Attachment->new (lan => $lan, eth => $machine_eth);
			push @{$switch->{attachments}}, Attachment->new (lan => $lan, eth => $eth);
			
			# Then use the next NIC
			$eth++;
		}
	}
}

sub install_packages {
	my ($lab, $machine, $packages, $use_podman) = @_;

	my $folder = "$lab->{out_dir}/$machine->{name}/usr/share/to_install/";
	
	my $cmd = "apt-get download $packages";
	
	my $cwd = getcwd;
	
	`mkdir -p $folder`;
	
	chdir $folder;
	
	if('/usr/bin/podman') {
		print "Using podman to download Debian Buster packages!\n";
		system("podman run -v .:/wdir:z --workdir /wdir -it --rm debian:bullseye sh -c 'apt-get update && $cmd'");
	} elsif (-e '/usr/bin/apt') {
		print "Using system apt - cannot guaruntee success if system does not use Debian Bullseye!\n";
		system($cmd);
	} else {
		die 'Cannot find podman or apt - cannot install packages!';
	}
	
	chdir $cwd;
	
	$machine->{startup_buffer} .= "\nenv DEBIAN_FRONTEND=noninteractive dpkg -i /usr/share/to_install/*.deb";
	
	print "$cwd\n";
}

1;
