package Git::Flux::Utils;

use Mouse::Role;

use List::MoreUtils 'all';

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

    my $cmd = $repo->command(
        diff => qw/ --no-ext-diff --ignore-submodules --quiet --exit-code /
    );
    $cmd->close;
    my $diff = $cmd->exit;

    $cmd = $repo->command(
        'diff-index' => qw/ --cached --quiet --ignore-submodules HEAD -- /
    );
    $cmd->close;
    my $diff_index = $cmd->exit;

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
sub git_is_branch_merged_into {
    my $self               = shift;
    my ( $subject, $base ) = @_;
    my $repo               = $self->{'repo'};

    my @all_merges = map { $_ =~ s/^\*?\s+//; $_; }
                    $repo->run(
                        branch => qw/ --no-color --contains /, $subject
                    );

    return grep { $_ eq $base } @all_merges;
}

sub gitflux_has_master_configured {
    my $self   = shift;
    my $repo   = $self->{'repo'};
    my $master = $repo->run( config => qw/ --get gitflux.branch.master / );

    return ( defined $master and $master ne '' ) &&
           $self->git_local_branch_exists($master);
}

sub gitflux_has_devel_configured {
    my $self  = shift;
    my $repo  = $self->{'repo'};
    my $devel = $repo->run( config => qw/ --get gitflux.branch.devel / );

    return ( defined $devel and $devel ne '' ) &&
           $self->git_local_branch_exists($devel);
}

sub gitflux_has_prefixes_configured {
    my $self    = shift;
    my $repo    = $self->{'repo'};
    my @results = map {
        $repo->run( config => '--get', "gitflux.prefix.$_" );
    } qw/ feature release hotfix support versiontag /;

    return all { defined $_ and $_ } @results;
}

sub gitflux_is_initialized {
    my $self = shift;
    my $repo = $self->{'repo'};

    return $self->gitflux_has_master_configured &&
           $self->gitflux_has_devel_configured  &&
           (
               $repo->run( config => qw/ --get gitflux.branch.master / ) ne
               $repo->run( config => qw/ --get gitflux.branch.devel /  )
           )                                    &&
           $self->gitflux_has_prefixes_configured;
}

sub gitflux_load_settings {
    my $self = shift;
    my $repo = $self->{'repo'};

    $self->{'dit_git_dir'}   = $repo->run( 'rev-parse' => '--git-dir' );

    $self->{'master_branch'} = $repo->run(
        config => qw/ --get gitflux.branch.master /
    );

    $self->{'devel_branch'}  = $repo->run(
        config => qw/ --get gitflux.branch.devel /
    );

    $self->{'origin_branch'} = $repo->run(
        config => qw/ --get gitflux.origin /
    ) || 'origin';
}

# Inputs:
# $1 = name prefix to resolve
# $2 = branch prefix to use
#
# Searches branch names from git_local_branches() to look for a unique
# branch name whose name starts with the given name prefix.
#
# There are multiple exit codes possible:
# 0: The unambiguous full name of the branch is written to stdout
#    (success)
# 1: No match is found.
# 2: Multiple matches found. These matches are written to stderr
sub gitflux_resolve_nameprefix {
    my $self              = shift;
    my ( $name, $prefix ) = @_;
    my $repo              = $self->{'repo'};

    # check for perfect match
    if ( $self->git_local_branch_exists( $prefix . $name ) ) {
        print "$name\n";
        return 0;
    }

    my @matches = grep { $_ =~ /^$prefix$name/ }
                  $self->git_local_branches;


    if ( @matches == 0 ){
        warn "No branch matches prefix '$name'\n";
        return 1;
    } else {
        if ( @matches == 1 ) {
            my $match = shift @matches;
            $match =~ s/^\Q$prefix\E//;
            warn "$match\n";

            return 0;
        } else {
            warn "Multiple branches match prefix '$name':\n";
            warn "- $_\n" for @matches;

            return 2;
        }
    }
}

sub require_git_repo {
    Git::Repository->new;
}

sub require_gitflux_initialized {
    my $self = shift;

    $self->gitflux_is_initialized
        or die 'fatal: Not a gitflux-enabled repo yet. ' .
               qq{Please run "git flux init" first.\n};
}

sub require_clean_working_tree {
    my $self   = shift;
    my $result = $self->git_is_clean_working_tree;

    $result eq 1
        and die "fatal: Working tree contains unstaged changes. Aborting.\n";

    $result eq 2
        and die "fatal: Index contains uncommitted changes. Aborting.\n";
}

sub require_local_branch {
    my $self = shift;
    my $br   = shift;

    $self->git_local_branch_exists($br)
        or die "fatal: Local branch '$br' does not exist and is required.\n";
}

sub require_remote_branch {
    my $self = shift;
    my $br   = shift;

    grep { $_ eq $br } $self->git_remote_branches
        or die "Remote branch '$br' does not exist and is required.\n";
}

sub require_branch {
    my $self = shift;
    my $br   = shift;

    grep { $_ eq $br } $self->git_all_branches
        or die "Branch '$br' does not exist and is required.\n";
}

sub require_branch_absent {
    my $self   = shift;
    my $branch = shift;
    my $repo   = $self->{'repo'};

    grep { $_ eq $branch } $self->git_all_branches
        or die "Branch '$branch' already exists. Pick another name.\n";
}

sub require_tag_absent {
    my $self = shift;
    my $tag  = shift;

    grep { $_ eq $tag } $self->git_all_tags
        or die "Tag '$tag' already exists. Pick another name.\n";
}

sub require_branches_equal {
    my $self          = shift;
    my ( $br1, $br2 ) = @_;
    my $repo          = $self->{'repo'};

    my $status = $self->git_compare_branches( $br1, $br2 );

    if ( $status > 0 ) {
        warn "Branches '$br1' and '$br2' have diverged.\n";

        if ( $status == 1 ) {
            die "And branch '$br1' may be fast-forwarded.\n";
        } elsif ( $status == 2 ) {
            warn "And local branch '$br1' is ahead of '$br2'.\n";
        } else {
            die "Branches need merging first.\n";
        }
    }
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

=head2 git_local_branches

Return list of all local git branches.

=head2 git_remote_branches

Return list of all remote git branches.

=head2 git_all_branches

Return list of all git branches, both local and remote.

=head2 git_all_tags

Return list of all git tags.

=head2 git_current_branch

Return the current git branch.

=head2 git_is_clean_working_tree

Return a numbered code representing the cleanliness of the Git repository.

=over 4

=item 0

The repo is clean.

=item 1

Unclean working directory. This means stuff is waiting to be added to
the staging area / index.

=item 2

Unclean index. This means stuff needs to be committed.

=back

=head2 git_repo_is_headless

Returns a boolean on whether the Git repo is headless or not.

=head2 git_local_branch_exists($name)

Returns a boolean on whether a certain local branch exists.

=head2 git_branch_exists($name)

Returns a boolean on whether a Git branch exists.

=head2 git_tag_exists($name)

Returns a boolean on whether a Git tag exists.

=head2 git_compare_branches($branch1, $branch2)

Compared two git branches and checks whether their I<origin> coutnerparts have
diverged and need merging first. Returns a numbered code:

=over 4

=item 0

Branch heads point to the same commit

=item 1

First given branch needs fast-forwarding

=item 2

Second given branch needs fast-forwarding

=item 3

Branch needs a real merge

=item 4

There is no merge base, i.e. the branches have no common ancestors

=back

=head2 git_is_branch_merged_into($branch1, $branch2)

Checks whether branch 1 is succesfully merged into 2.

=head2 gitflux_has_master_configured

Return a boolean on whether the gitflux master is configured.

=head2 gitflux_has_devel_configured

Returns a boolean on whether the gitflux devel is configured.

=head2 gitflux_has_prefixes_configured

Returns a boolean on whether the gitflux prefixes are configured.

=head2 gitflux_is_initialized

Returns a boolean on whether gitflux itself is configured.

=head2 gitflux_load_settings

Loads all the gitflux settings.

=head2 gitflux_resolve_nameprefix

Returns a boolean on whether the gitflux devel is configured.

=head2 require_git_repo

Asserts a certain directory is a git repository.

=head2 require_gitflux_initialized

Asserts gitflux was already initialized.

=head2 require_clean_working_tree

Asserts the working tree is clean.

=head2 require_local_branch($branch)

Asserts there's a local branch with a given name.

=head2 require_remote_branch($branch)

Asserts there's a local branch with a given name.

=head2 require_branch($branch)

Asserts a certain branch exists.

=head2 require_branch_absent($name)

Returns a boolean on whether a branch exists.

=head2 require_tag_absent($branch)

Asserts that a certain tag is absent.

=head2 require_branches_equal($branch1, $branch2)

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

