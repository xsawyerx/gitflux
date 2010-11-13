package Git::Flux::Utils;

use strict;
use warnings;
use mixin::with 'Git::Flux';

sub git_local_branches {
    my $self     = shift;
    my $repo     = $self->{'repo'};
    my @branches = map { $_ =~ s/^\*?\s+//; $_; }
                  $repo->run( branch => '--no-color' );

    return @branches;
}

sub git_remote_branches {
    my $self     = shift;
    my $repo     = $self->{'repo'};
    my @branches = map { $_ =~ s/^\*?\s+//; $_; }
                   $repo->run( branch => '-r', '--no-color' );

    return @branches;
}

sub git_all_branches {
    my $self     = shift;
    my $repo     = $self->{'repo'};
    my @branches = ( $self->git_local_branches, $self->git_remote_branches );

    return @branches;
}

sub git_all_tags {
    my $self = shift;
    my $repo = $self->{'repo'};
    my @tags = $repo->run('tag');

    return @tags;
}

sub git_current_branch {
    my $self = shift;
    my $repo = $self->{'repo'};

    my ($branch) = map  { $_ =~ s/^\*\s+//g; $_; }
                   grep { $_ !~ /no branch/      }
                   grep { $_ =~ /^\*\s/          }
                   $repo->run( branch => '--no-color' );

    return $branch;
}

sub require_branch_absent {
    my $self   = shift;
    my $branch = shift;
    my $repo   = $self->{'repo'};

    my @branches = $self->git_all_branches;

    if ( grep { $_ eq $branch } @branches ) {
        die "Branch '$branch' already exists. Pick another name.\n";
    }
}

sub git_branch_exists {
    my $self     = shift;
    my $branch   = shift;
    my @branches = $self->git_all_branches;

    grep { $_ eq $branch } @branches;
}

sub require_branches_equal {
    my $self          = shift;
    my ( $br1, $br2 ) = @_;
    my $repo          = $self->{'repo'};

}

sub is_interactive {
    return -t STDIN && -t STDOUT;
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

=head2 is_interactive

Returns boolean on whether we're in interactive mode.

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

