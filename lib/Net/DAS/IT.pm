package Net::DAS::IT;
use 5.010;
use strict;
use warnings;
use Data::Dumper;

sub register {
    return { 
		tlds => [qw(it co.it)],
		public => {
				host => 'das.nic.it',
				port => 4343,
				},
	};
}

1;