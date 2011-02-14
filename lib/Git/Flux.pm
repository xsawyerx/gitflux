package Git::Flux;

use Mouse;

use Git::Repository;

# common
with 'Git::Flux::Utils';

# commands 
with 'Git::Flux::Command::init';
with 'Git::Flux::Command::help';

our $VERSION = '0.0_03';

#Attribut Class
has 'dir'  => (is => 'ro', isa => 'Str');
has 'repo' => (is => 'ro', isa => 'Str');

# TODO: add variables here for prefix (origin, feature, etc.)


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

=head2 new

Create a new object of Git::Flux.

=head3 dir

The directory which the Git::Flux instance will be working on.

You can also set this using the C<GITFLUX_DIR> environment variable.

=head3 repo

Internal L<Git::Repository> object that Git::Flux uses to do all the C<Git>
work.

You can construct your own and provide it on initialize.

=head2 run

=head2 create_repo

A small helper function to create a repository. The directory is taken from
the C<dir> hash key in the object. If one does not exist (that means it was
not provided in C<new>), it uses the current directory.

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

