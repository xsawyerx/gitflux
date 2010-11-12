package Git::Flux::Utils;

use strict;
use warnings;
use mixin::with 'Git::Flux';

sub require_branch_absent {
    my $self   = shift;
    my $branch = shift;
    my $repo   = $self->{'repo'};

    # get all branches
    my @branches = map { $_ =~ s/^\*?\s+//; $_; }
                   map { $repo->run( @{$_}, '--no-color' ); }
                   [ 'branch' ], [ branch => '-r' ]; 

    if ( grep { $_ eq $branch } @branches ) {
        die "Branch '$branch' already exists. Pick another name.\n";
    }
}

sub git_branch_exists {
    my $self   = shift;
    my $branch = shift;
    my $repo   = $self->{'repo'};

}

sub require_branches_equal {
    my $self          = shift;
    my ( $br1, $br2 ) = @_;
    my $repo          = $self->{'repo'};

}

1;

__END__

=head1 NAME

Git::Flux::Utils - Common utility functions for Gitflux

=head1 DESCRIPTION

This provides a few command utilities that is shared between Gitflux commands.

=head1 SUBROUTINES/METHODS

=head2 require_branch_absent($name)

Returns a boolean on whether a branch exists.

=head2 git_branch_exists($name)

Asserts that a branch exists.

=head2 require_branches_equal( $branch1, $branch2 )

Asserts that two branches are equal.

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

