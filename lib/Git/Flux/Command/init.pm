package Git::Flux::Command::init;

use Git::Flux::Response;

use Mouse::Role;
use Try::Tiny;

with qw/Git::Flux::Term/;

sub init {
    my $self  = shift;
    my $force = shift;
    my $dir   = $self->dir;

    my ( $failed, $repo, $master_branch, $devel_branch, $prefix );

    if ($force) {
        $force eq '-f' or die "Improper opt to init: $force\n";
    }

    try {
        $self->repo->create(init => $dir);
    }catch{
        warn $_;
        $failed++;
    };

    unless ($failed) {
        $self->git_repo_is_headless or $self->require_clean_working_tree;
    }

    if ( $self->gitflux_is_initialized && ! $force ) {
        die "Already initialized for gitflux.\n" .
            "To force reinitialization, use: git flux init -f\n";
    }

    # set up master branch
    if ( $self->gitflux_has_master_configured && ! $force ) {
        $master_branch =
            $self->repo->run( config => qw/ --get  gitflux.branch.master / );
    } else {
        # Two cases are distinguished:
        # 1. A fresh git repo (without any branches)
        #    We will create a new master/devel branch for the user
        # 2. Some branches do already exist
        #    We will disallow creation of new master/devel branches and
        #    rather allow to use existing branches for git-flow.
        my ( $check_existence, $default_suggestion );
        my @local_branches = $self->git_local_branches;

        if ( @local_branches == 0 ) {
            print "No branches exist yet. Base branches must be created now.\n";
            $check_existence    = 0;
            $default_suggestion = $self->repo->run(
                config => qw/ --get gitflux.branch.master /
            ) || 'master';
        } else {
            print "\nWhich branch should be used for production releases?\n";
            print map { $_=~ s/^(.*)$/   - $1/; $_; } $self->git_local_branches;
            print "\n";

            $check_existence = 1;
            my @guesses = (
                $self->repo->run( config => qw/ --get gitflux.branch.master / ),
                qw/ production main master /
            );

            foreach my $guess (@guesses) {
                if ( $self->git_local_branch_exists($guess) ) {
                    $default_suggestion = $guess;
                    last;
                }
            }
        }

        my $prompt = 'Branch name for production releases: ' .
                     "[$default_suggestion] ";

        $master_branch = $self->answer($prompt, $default_suggestion);

        if ($check_existence) {
            $self->git_local_branch_exists($master_branch)
                or die "Local branch '$master_branch' does not exist.\n";
        }

        $self->repo->run( config => 'gitflux.branch.master', $master_branch );
    }

    # set up devel branch
    if ( $self->gitflux_has_devel_configured && ! $force ) {
        $devel_branch = $self->repo->run( config => qw/--get gitflux.branch.devel/ );
    } else {
        # Again, the same two cases as with the master selection are
        # considered (fresh repo or repo that contains branches)
        my ( $check_existence, $default_suggestion );
        my @local_branches_wo_master = grep { $_ !~ /^\Q$master_branch\E$/ }
            $self->git_local_branches;

        if ( @local_branches_wo_master == 0 ) {
            $check_existence = 0;
            $default_suggestion = $self->repo->run(
                config => qw/ --get gitflux.branch.devel /
            ) || 'devel';
        } else {
            print "\nWhich branch should be used for integration of the " .
                  "\"next release\"?\n";
            print map { $_=~ s/^(.*)$/   - $1/; $_; }
                grep { $_ !~ /^\Q$master_branch$/ } $self->git_local_branches;
            print "\n";

            $check_existence = 1;
            my @guesses = (
                $self->repo->run( config => qw/ --get gitflux.branch.devel / ),
                qw/ devel develop int integration master /
            );

            foreach my $guess (@guesses) {
                if ( $self->git_local_branch_exists($guess) ) {
                    $default_suggestion = $guess;
                    last;
                }
            }
        }

        # on and on

        my $prompt = 'Branch name for "next release" development: ' .
                     "[$default_suggestion] ";

        $devel_branch = $self->answer($prompt, default_suggestion);

        if ( $master_branch eq $devel_branch ) {
            die "Production and integration branches should differ.\n";
        }

        if ($check_existence) {
            $self->git_local_branch_exists($devel_branch)
                or die "Local branch '$devel_branch' does not exist.\n";
        }

        $self->repo->run( config => 'gitflux.branch.devel', $devel_branch );
    }

    # Creation of HEAD
    # ----------------
    # We create a HEAD now, if it does not exist yet (in a fresh repo). We need
    # it to be able to create new branches.
    my $created_gitflux_branch;
    my $cmd = $self->repo->command( 'rev-parse' => qw/ --quiet --verify HEAD / );
    $cmd->close;

    if ( $cmd->exit == 1 ) {
        $self->repo->run( 'symbolic-ref' => 'HEAD', "refs/heads/$master_branch" );
        $self->repo->run( commit => qw/--allow-empty --quiet -m/, 'Initial commit' );
        $created_gitflux_branch = 1;
    }

    # Creation of master
    # ------------------
    # At this point, there always is a master branch: either it existed already
    # (and was picked interactively as the production branch) or it has just
    # been created in a fresh repo

    # Creation of devel
    # -------------------
    # The devel branch possibly does not exist yet. This is the case when,
    # in a git init'ed repo with one or more commits, master was picked as the
    # default production branch and devel was "created".  We should create
    # the devel branch now in that case (we base it on master, of course)
    if ( ! $self->git_local_branch_exists($devel_branch) ) {
        $self->repo->run( branch => '--no-track', $devel_branch, $master_branch );
        $created_gitflux_branch = 1;
    }

    # assert gitflux initialization
    $self->gitflux_is_initialized;

    # switch to devel if newly created
    if ($created_gitflux_branch) {
        $self->repo->run( checkout => '-q', $devel_branch );
    }

    # finally, ask the user for naming conventions (branch and tag prefixes)
    if (
        $force ||
        ! $self->repo->run( config => qw/--get gitflux.prefix.feature/    ) ||
        ! $self->repo->run( config => qw/--get gitflux.prefix.release/    ) ||
        ! $self->repo->run( config => qw/--get gitflux.prefix.hotfix/     ) ||
        ! $self->repo->run( config => qw/--get gitflux.prefix.support/    ) ||
        ! $self->repo->run( config => qw/--get gitflux.prefix.versiontag/ )
    ) {
        print "\nHow to name your supporting branch prefixes?\n";
    }

    foreach my $type ( qw/ feature release hotfix support versiontag / ) {
        my $cmd = $self->repo->command( config => '--get', "gitflux.prefix.$type" );
        $cmd->close;

        my $prefix = '';

        if ( $cmd->exit == 1 or $force ) {
            my $default_suggestion = $self->repo->run(
                config => '--get', "gitflux.prefix.$type"
            ) || "$type/";

            # version tag has its own default suggestion
            $type eq 'versiontag' and $default_suggestion = 'v';

            # version tag has its own prompt text
            my $prompt = $type eq 'versiontag'                        ?
                         "Version tag prefix? [$default_suggestion] " :
                         ucfirst $type . " branches? [$default_suggestion] ";

            my $answer = $self->answer($prompt, $default_suggestion);

            defined $answer and chomp $answer;
            ( defined $answer and $answer ne '' )
                or $answer = $default_suggestion;

            # - means empty prefix, otherwise take the answer (or default)
            ( defined $answer and $answer eq '-' )
                or $prefix = $answer;

            $self->repo->run( config => "gitflux.prefix.$type", $prefix );
        }
    }
}

1;

__END__

=head1 NAME

Git::Flux::Command::init - init command to Gitflux

=head1 DESCRIPTION

This provides initialization functionality to Gitflux.

Gitflux can only work once it has been initialized, and that's what C<init>
provides.

=head1 SUBROUTINES/METHODS

=head2 init

Initialize a repo.

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

