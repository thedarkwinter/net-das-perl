package Net::DAS::BE;
use 5.010;
use strict;
use warnings;
use Data::Dumper;

sub register {
    return { 
		tlds => [qw(be)],
		public => {
				host => 'das.dns.be',
				port => 4343,
				},
		dispatch => [undef, undef],
	};
}

1;