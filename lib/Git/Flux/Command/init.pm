package Git::Flux::Command::init;

use strict;
use warnings;
use mixin::with 'Git::Flux';
use Try::Tiny;
use Term::ReadLine;

sub init {
    my $self  = shift;
    my $force = shift;
    my $dir   = $self->{'dir'};
    my $term  = Term::ReadLine->new('Gitflux');

    my ( $repo, $master_branch );

    if ($force) {
        $force eq '-f' or die "Improper opt to init: $force\n";
    }

    try     { Git::Repository->new( work_tree => $dir ) }
    catch   {
        $repo = $self->{'repo'} =
            Git::Repository->create( 'init' => { cwd => $dir } );
    } finally {
        unless (@_) {
            $self->git_repo_is_headless or $self->require_clean_working_tree;
        }
    };

    if ( $self->gitflux_is_initialized && ! $force ) {
        die "Already initialized for gitflux.\n" .
            "To force reinitialization, use: git flux init -f\n";
    }

    if ( $self->gitflux_has_master_configured && ! $force ) {
        $master_branch =
            $repo->run( config => qw/ --get  gitflux.branch.master / );
    } else {
        # Two cases are distinguished:
        # 1. A fresh git repo (without any branches)
        #    We will create a new master/develop branch for the user
        # 2. Some branches do already exist
        #    We will disallow creation of new master/develop branches and
        #    rather allow to use existing branches for git-flow.
        my ( $check_existence, $default_suggestion );
        my @local_branches  = $self->git_local_branches;

        if ( @local_branches == 0 ) {
            print "No branches exist yet. Base branches must be created now.\n";
            $check_existence    = 0;
            $default_suggestion = $repo->run(
                config => qw/ --get gitflux.branch.master /
            ) || 'master';
        } else {
            print "\nWhich branch should be used for production releases?\n";
            print map { $_=~ s/^(.*)$/   - $1/; $_; } $self->git_local_branches;
            $check_existence = 1;
            my @guesses =
                ( $repo->run( config => qw/ --get gitflux.branch.master / ),
                qw/ production main master / );

            foreach my $guess (@guesses) {
                if ( $self->git_local_branch_exists($guess) ) {
                    $default_suggestion = $guess;
                    last;
                }
            }
        }

        my $prompt = 'Branch name for production releases: ' .
                     "[$default_suggestion] ";

        my $answer     = readline($prompt);
        $master_branch = $answer || $default_suggestion;

        if ($check_existence) {
            $self->git_local_branch_exists($master_branch)
                or die "Local branch '$master_branch' does not exist.\n";
        }

        $repo->run( config => 'gitflux.branch.master', $master_branch );
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

