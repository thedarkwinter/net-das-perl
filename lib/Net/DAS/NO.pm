package Net::DAS::NO;
use 5.010;
use strict;
use warnings;
use Data::Dumper;

sub register {
    return { 
		tlds => [qw(no)],
		public => {
				host => 'whois.norid.no',
				port => 79,
				},
		dispatch => [undef, \&parse],
	};
}

sub parse {
	chomp (my $i = uc(shift));
	return 1 if uc($i) =~ m/IS AVAILABLE/;
	return 0 if uc($i) =~ m/IS DELEGATED/;
    return (-100) ; # failed to determine/parse
}




1;