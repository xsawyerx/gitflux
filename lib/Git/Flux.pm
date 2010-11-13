package Git::Flux;

use strict;
use warnings;

use Git::Repository;

# common
use mixin 'Git::Flux::Utils';

# commands
use mixin 'Git::Flux::Command::init';
use mixin 'Git::Flux::Command::help';
use mixin 'Git::Flux::Command::feature';

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %opts  = @_;
    my $self  = {
        dir  => $opts{'dir'},
        repo => $opts{'repo'},
    };

    # TODO: add variables here for prefix (origin, feature, etc.)

    bless $self, $class;
}

sub run {
    my $self = shift;
    my ( $cmd, @opts ) = @_;

    # run help if no other cmd
    $cmd ||= $self->help();

    if ( not defined $self->{'repo'} and $cmd ne 'init' ) {
        # create the repo now
        $self->create_repo();
    }

    $self->$cmd(@opts);
}

sub create_repo {
    my $self = shift;
    my $dir  = $self->{'dir'} || '.';
    $self->{'repo'} = Git::Repository->new( work_tree => $dir );
}

1;

__END__

=head1 NAME

Git::Flux - A Perl port of gitflow

=head1 DESCRIPTION

We like gitflow and we like Perl and when we heard gitflow needs to be rewritten
in order to be more portable, we decided to get in gear.

C<gitflux> is the love child or Perl and gitflow.

=head1 SUBROUTINES/METHODS

=head1 AUTHORS

Sawyer X, C<< <xsawyerx at cpan.org> >>

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 BUGS

Please use the Github Issues tracker.

=head1 ACKNOWLEDGEMENTS

c<gitflow>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

