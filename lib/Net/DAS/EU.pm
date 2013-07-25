package Net::DAS::EU;
use 5.010;
use strict;
use warnings;
use Data::Dumper;

sub register {
    return { 
		tlds => [qw(eu)],
		public => {
				host => 'das.eu',
				port => 4343,
				},
		registrar =>	{
				host => 'das.registry.eu',
				port => 4343,
				},
		dispatch => [\&query, undef],
	};
}

sub query { 
	my $d = shift;
	$d =~ s/.eu.*$//;
	return "get 2.0 " . $d; 
}

1;