package Net::DAS::RO;
use 5.010;
use strict;
use warnings;

sub register {
    return {
        tlds   => [qw (ro)],
        public => {
            host => 'rest2-test.rotld.ro',
            port => 4343,
        },
        registrar => {
            host => 'dac.nic.uk',
            port => 3043,
        },
    	nl => "\r\n",
        dispatch  => [ undef, undef ],
    };
}

1;

=pod

=head1 NAME

Net::DAS::RO - Net::DAS .RO extension.

See L<Net::DAS>

=head1 AUTHOR

Michael Holloway <michael@thedarkwinter.com>

=head1 LICENSE

Artistic License

=cut 
