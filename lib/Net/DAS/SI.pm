package Net::DAS::SI;
use 5.010;
use strict;
use warnings;
use Data::Dumper;

sub register {
    return { 
		tlds => [qw(si)],
		public => {
				host => 'das.arnes.si',
				port => 4343,
				},
		dispatch => [undef, \&parse],
	};
}

sub parse {
	chomp (my $i = uc(shift));
	return 1 if uc($i) =~ m/IS AVAILABLE/;
	return 0 if uc($i) =~ m/IS REGISTERED/;
	return -1 if uc($i) =~ m/IS FORBIDDEN/;
    return (-100) ;
}

1;