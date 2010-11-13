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

sub git_is_clean_working_tree {
    my $self = shift;
    my $repo = $self->{'repo'};

    my $diff       = $repo->run(
        diff => qw/ --no-ext-diff --ignore-submodules --quiet --exit-code /
    );

    my $diff_index = $repo->run(
        'diff-index' => qw/ --cached --quiet --ignore-submodules HEAD -- /
    );

    $diff       and return 1;
    $diff_index and return 2;

    return 0;
}

sub git_repo_is_headless {
    my $self   = shift;
    my $repo   = $self->{'repo'};
    my $result = $repo->run( 'rev-parse' => qw/ --quiet --verify HEAD / );

    return not $result;
}

sub git_local_branch_exists {
    my $self     = shift;
    my $branch   = shift;
    my @branches = $self->git_local_branches;

    grep { $_ eq $branch } @branches;
}

sub git_branch_exists {
    my $self     = shift;
    my $branch   = shift;
    my @branches = $self->git_all_branches;

    grep { $_ eq $branch } @branches;
}

sub git_tag_exists {
    my $self = shift;
    my $tag  = shift;
    my @tags = $self->git_all_tags;

    grep { $_ eq $tag } @tags;
}

# Tests whether branches and their "origin" counterparts have diverged and need
# merging first. It returns error codes to provide more detail, like so:
#
# 0    Branch heads point to the same commit
# 1    First given branch needs fast-forwarding
# 2    Second given branch needs fast-forwarding
# 3    Branch needs a real merge
# 4    There is no merge base, i.e. the branches have no common ancestors
sub git_compare_branches {
    my $self        = shift;
    my ( $c1, $c2 ) = @_;
    my $repo        = $self->{'repo'};

    my $commit1 = $repo->run( 'rev-parse' => $c1 );
    my $commit2 = $repo->run( 'rev-parse' => $c2 );

    if ( $commit1 != $commit2 ) {
        my $cmd = $repo->command( 'merge-base' => $c1, $c2 );
        $cmd->close;

        $cmd->exit == 0          and return 4;
        $commit1 eq $cmd->stdout and return 1;
        $commit2 eq $cmd->stdout and return 2;

        return 3;
    } else {
        return 0;
    }
}

# Checks whether branch $1 is succesfully merged into $2
sub git_is_merged_into {
    my $self               = shift;
    my ( $subject, $base ) = @_;
    my $repo               = $self->{'repo'};

    my @all_merges = map { $_ =~ s/^\*?\s+//; $_; }
                    $repo->run(
                        branch => qw/ --no-color --contains /, $subject
                    );

    return grep { $_ eq $base } @all_merges;
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

