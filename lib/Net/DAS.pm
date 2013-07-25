package Net::DAS;
use 5.010;
use strict;
use warnings;
use Carp qw (croak);
use Module::Load;
use IO::Socket::INET;
use Time::HiRes qw (usleep);

use Data::Dumper;

our $VERSION = '0.09';
our @modules = qw (EU BE NO LT UK SI IT);

sub new {
	my $class = shift;
	my $self = shift || {};
	bless $self, $class;
	$self->{tlds} = {};
	$self->{use_registrar} = undef unless exists $self->{use_registrar};
	$self->{timeout} = 4 unless exists $self->{timeout};
	$self->{_request} = \&_send_request unless exists $self->{_request};
	our (@modules);
	@modules = @{$self->{modules}} if exists $self->{modules};
	my ($m,$t);
	foreach (@modules) {
		$m = 'Net::DAS::'.uc($_);
	    eval { 
			load($m);
			$self->{$m} = $m->register();
			foreach my $t (@{$self->{$m}->{tlds}}) {
				$self->{tlds}->{$t} = $m;
			}
		};
	    if ($@) {
			warn "Warning: unable to load module $m: $@\n";
			next;
		}
	}
	#print Dumper $self;
	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->_close_ports() if defined $self->{modules};
	undef $self->{modules};
}

sub _close_ports {
	my $self = shift;
	return unless defined $self->{modules};
	foreach my $k (@{$self->{modules}}) {
		my $m = 'NET::DAS'.$k;
		next unless exists $self->{$m} && !defined $self->{$m}->{sock} && $self->{$m}->{sock}->connected();
		$self->{$m}->{sock}->syswrite($self->{$m}->{close_cmd}) if exists $self->{$m}->{close_cmd};
		undef $self->{$m}->{sock};
	}
	return;
}


sub _split_domain
{
	my ($self,$i) = @_;
	return ($1,$2) if $i =~ m/(.*)\.(.*\..*)/ && exists $self->{tlds}->{$2};
	return ($1,$2) if $i =~ m/(.*)\.(.*)/;
	croak('Invalid domain ' . $i);
	return;
}

sub _send_request {
	my ($self,$q,$m,$keepopen) = @_;
	my $svc = ($self->{use_registrar}  && exists $self->{$m}->{registrar}) ? 'registrar' : 'public';
	my $h = $self->{$m}->{$svc}->{host};
	my $p = defined $self->{$m}->{$svc}->{port} ? $self->{$m}->{public}->{port} : 4343;
	my $pr = defined $self->{$m}->{$svc}->{proto} ? $self->{$m}->{public}->{proto} : 'tcp';
	if (!$self->{$m}->{sock} || !$self->{$m}->{sock}->connected()) {
		$self->{$m}->{sock} = IO::Socket::INET->new(PeerAddr => $h, PeerPort => $p, Proto=> $pr, Timeout => 30) || croak("Unable to connect to $h:$p $@");
	}
	#usleep($self->{$m}->{delay}) if exists $self->{$m}->{delay};
	$self->{$m}->{sock}->syswrite($q."\n");
	my ($res,$buf);
	while ($self->{$m}->{sock}->sysread($buf,1024)) { 
		$res .= $buf;
		last if $self->{$m}->{sock}->atmark; 	
	}
	unless (exists $self->{$m}->{close_cmd}) {
		$self->{$m}->{sock}->close();
		undef $self->{$m}->{sock};
	}
	#print Dumper $res;
	return $res;
}

sub _parse {
	my $self = shift;
	chomp (my $i = uc(shift));
	return -3 if $i =~ m/IP ADDRESS BLOCKED/;
	return 1 if $i =~ m/.*STATUS:\sAVAILABLE/;
	return 0 if $i =~ m/.*STATUS:\sNOT AVAILABLE/;
	return -1 if $i =~ m/.*STATUS:\sNOT VALID/;
	return (-100) ;
}

sub lookup {
	my ($self,@domains) = @_;
	return { 'avail'=>-1,'reason'=>'NO DOMAIN SPECIFIED' } unless @domains;
	my ($r,$b) = {};
	foreach my $i (@domains)
	{
		chomp($i);
		$r = {'domain' => $i};
		eval {
			($r->{'label'},$r->{'tld'}) = $self->_split_domain($i);
			croak ("TLD ($r->{'tld'}) not supported") unless ($r->{'module'} = $self->{tlds}->{$r->{'tld'}});
			my ($disp) = defined $self->{$r->{module}}->{dispatch} ? $self->{$r->{module}}->{dispatch} : [];
			chomp ($r->{'query'} = defined($disp->[0]) ? $disp->[0]->($r->{'domain'}) : $r->{'domain'});

			local $SIG{ALRM} = sub { die "TIMEOUT\n" };
			alarm $self->{timeout};
			chomp ($r->{'response'} = $self->{_request}->($self,$r->{'query'},$r->{module}));
			alarm 0;

			$r->{'avail'} = defined($disp->[1]) ? $disp->[1]->($r->{'response'}) : $self->_parse($r->{'response'});
			$r->{'reason'} = 'AVAILABLE' if $r->{'avail'} == 1;
			$r->{'reason'} = 'NOT AVAILABLE' if $r->{'avail'} == 0;
			$r->{'reason'} = 'NOT VALID' if $r->{'avail'} == -1;
			$r->{'reason'} = 'NOT AUTHORIZED' if $r->{'avail'} == -2;
			$r->{'reason'} = 'IP BLOCKED' if $r->{'avail'} == -3;
			$r->{'reason'} = 'UNABLE TO PARSE RESPONSE' if $r->{'avail'} == -100;
		};
		if ($@) {
			chomp($r->{reason} = $@);
			$r->{avail}=-1;
		}
		$b->{$i} = $r;
	};
	#print Dumper $b;
	$self->_close_ports();
	return $b;
}

sub available {
	my ($self,$dom) = @_;
	my $r = $self->lookup(($dom));
	return $r->{$dom}->{'avail'};
}

1;