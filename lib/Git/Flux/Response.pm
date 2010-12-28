package Git::Flux::Response;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    my $self = \%params;
    bless $self, $class;
    return $self;
}

sub is_success {
    my $self = shift;
    return $self->{status};
}

sub message {
    my $self = shift;
    return $self->{message};
}

sub error {
    my $self = shift;
    return $self->{error};
}

1;
