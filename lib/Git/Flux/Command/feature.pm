package Git::Flux::Command::feature;

use strict;
use warnings;
use Carp;

use mixin::with 'Git::Flux';

# XXX missing
# - finish
# - rebase => need tests
# - publish => need tests
# - diff => need tests
# - checkout => need tests
# - pull => need tests

my $aliases = {
    co => 'checkout',
};

sub feature {
    my $self = shift;
    my $cmd = shift || 'list';

    $cmd = defined $aliases->{$cmd} ? $aliases->{$cmd} : $cmd;
    
    my $method = "feature_$cmd";

    $self->gitflux_load_settings();

    # dispatch to methods
    $self->$method(@_);
}

sub feature_start {
    my $self = shift;
    my $name = shift; 
    my $base = shift || $self->{'devel_branch'};
    
    my $repo = $self->{'repo'};

    $name or Carp::croak "Missing argument <name>";

    $name = $self->expand_nameprefix($name);
    $self->require_branch_absent($name);

    # TODO: handle fetch flag handling

    my $devel_br = $self->{devel_branch};
    my $origin   = $self->{origin_branch};

    # if remote exists, compare them
    if ( $self->git_branch_exists("$origin/$devel_br") ) {
        $self->require_branches_equal( $devel_br, "$origin/$devel_br" );
    }

    # create branch
    my $result = $repo->command( checkout => '-b' => $name => $base );
    $result->exit == 0
      or Carp::croak "Could not create feature branch '$name'";

    print << "_END_REPORT";
Summary of actions:
- A new branch '$name' was created, based on '$base'
- You are now on branch '$name'

Now, start committing on your feature. When done, use:

     git flow feature finish $name
_END_REPORT

}

sub feature_list {
    my $self = shift;

    my $repo   = $self->{repo};
    my $prefix = $self->feature_prefix();

    my @features_branches = grep { /^$prefix/ } $self->git_local_branches();

    if ( !scalar @features_branches ) {
        print << "__END_REPORT";
No feature branches exists.

You can start a new feature branch:

    git-flux feature start <name> [<base>]

__END_REPORT
        return;
    }

    my $current_branch = $self->git_current_branch();
    my $devel_branch   = $self->{'devel_branch'};

    foreach my $branch (@features_branches) {
        my $base = $repo->run( 'merge-base' => $branch => $devel_branch );
        my $develop_sha = $repo->run( 'rev-parse' => $devel_branch );
        my $branch_sha  = $repo->run( 'rev-parse' => $branch );
        if ( $branch eq $current_branch ) {
            print '* ';
        }
        else {
            print '  ';
        }
        print "$branch\n";
    }
}

sub feature_track {
    my ($self, $name) = @_;
    $name or Carp::croak "Missing argument <name>";

    $name = $self->expand_nameprefix($name);
    
    $self->require_clean_working_tree();
    $self->require_branch_absent($name);

    my $repo = $self->{'repo'};
    my $origin = $self->{'origin_branch'};

    $repo->run( 'fetch' => '-q' => $origin );

    my $origin_br = $origin.'/'.$name;
    $self->require_branch($origin_br);

    $repo->run( 'checkout' => '-b' => $name => $origin_br);

    print << "_END_REPORT";

Summary of actions:
- A new remote tracking branch '$name' was created
- You are now on branch '$name'

_END_REPORT
}

sub feature_pull {
    my $self   = shift;
    my $remote = shift;

    if ( !$remote ) {
        Carp::croak("Name a remote explicitly");
    }

    $current_branch = $self->git_current_branch();
    my $name = @_ == 1 ? $self->expand_nameprefix(shift) : $current_branch;

    my $prefix = $self->feature_prefix();

    # To avoid accidentally merging different feature branches into
    # each other, die if the current feature branch differs from the
    # requested $name argument.
    if ( $current_branch =~ /^$prefix/ ) {

        # we are on a local feature branch already, so $BRANCH must be
        # equal to the current branch
        $self->_avoid_accidental_cross_branch_action($name);
    }

    $self->require_clean_working_tree();

    my $repo = $self->{repo};

    if ( $self->git_branch_exists($name) ) {
        $self->_avoid_accidental_cross_branch_action($name) || Carp::croak("die");

        my $res = $repo->run( 'pull' => '-q' => $remote => $name );
        $res->exit == 0
          || die "Failed to pull from remote '$remote'";
        print "Pulled $remote's changes into $name\n";

        $res = $repo->run( 'fetch' => "-q" => $remote => $name );
        $res->exit == 0 || die "Fetch failed";

        $res = $repo->run( 'branch' => '--no-track' => $name => "FETCH_HEAD" );
        $res->exit == 0 || die "Branch failed";

        $res = $repo->run( 'checkout' => "-q" => $name );
        $res->exit == 0
          || die "Checking out new local branch failed";
        print "Created local branch $branch based on $remote's $name\n";
        return;
    }

    my $res = $repo->run( 'fetch', => "-q" => $remote => $name );
    $res->exit == 0 || die "Fetch failed";

    $res = $repo->run( 'branch' => '--no-track' => $name => "FETCH_HEAD" );
    $res->exit == 0 || die "Branch failed";

    $res = $repo->run( 'checkout', '-q', $name );
    $res->exit == 0 || die "Checking out new local branch failed";
    print "Created local branch $branch based on $remote's branch\n";
}

sub feature_checkout {
    my ( $self, $name ) = @_;

    if ( !$name ) {
        Carp::croak "Name a feature branch explicitly";
    }

    $name = $self->expand_nameprefix($name);
    $self->{repo}->run( 'checkout' => $name );
}

sub feature_diff {
    my $self = shift;
    my $name = shift;

    my $repo   = $self->{repo};
    my $prefix = $self->feature_prefix();

    if ( !defined $name ) {
        my $current_branch = $self->git_current_branch();
        if ( $current_branch !~ /^$prefix/ ) {
            Carp::croak("Not on a feature branch. Name one explicitly");
        }
        my $base = $repo->run( 'merge-base' => $devel => "HEAD" );
        $repo->run( 'diff' => $base );
        return;
    }

    $name = $self->expand_nameprefix($name);
    my $base = $repo->run( 'merge-base' => $self->{devel_branch} => $name );
    $repo->run( 'diff' => "$base..$name" );
}

sub feature_publish {
    my ( $self, $name ) = @_;

    $self->expand_nameprefix($name);

    my $repo   = $self->{repo};
    my $origin = $self->{origin_branch};

    $self->require_clean_working_tree();
    $self->require_branch($name);

    # XXX require_branch
    $repo->run( 'fetch' => "-q" => $origin );

    $self->require_branch_absent( $origin . "/" . $name );

    # create remote branch
    $repo->run( 'push'  => $origin => "$name:refs/heads/$name" );
    $repo->run( 'fetch' => "-q"    => $origin );

    # configure remote tracking
    $repo->run( 'config' => "branch.$name.remote" => $origin );
    $repo->run( 'config' => "branch.$name.merge"  => "refs/head/$name" );
    $repo->run( 'checkout' => $name );

    print << "_END_REPORT";
Summary of actions:
- A new remote branch '$name' was created
- The local branch '$name' was configured to track the remote branch
- You are now on branch '$name'

_END_REPORT

}

sub feature_rebase {
    my $self = shift;

    my ( $interactive, $name ) = @_;

    if ( @_ == 2 ) {
        $interactive = shift;
    }
    $name = $self->expand_nameprefix(shift);

    warn "Will try to rebase '$name'...\n";
    $self->require_clean_working_tree();
    $self->require_branch($name);

    my $repo = $self->{repo};
    $repo->run( 'checkout' => "-q" => $name );

    my @opts;
    push @opts, "-i" if $interactive;
    push @opts, $self->{devel_branch};
    $repo->run( 'rebase' => @opts );
}

sub _avoid_accidental_cross_branch_action {
    my ( $self, $name ) = @_;
    my $current_br = $self->git_current_branch();
    if ( $current_br ne $name ) {
        warn
"Trying to pull from $name while currently on branch '$current_br'.\n";
        warn "To avoid unintended merges, git-flow aborted.\n";
        return 0;
    }
    return 1.;
}

sub _feature_end {1}

sub expand_nameprefix {
    my ( $self, $name ) = @_;
    my $prefix = $self->feature_prefix();
    $self->expand_prefix( $prefix, $name );
}

1;

__END__

=head1 NAME

Git::Flux::Command::feature - feature command to Gitflux

=head1 DESCRIPTION

This provides feature branches functionality to Gitflux.

=head1 SUBROUTINES/METHODS

=head2 feature

Features can be started, finished, listed, etc.

=head2 feature_start

The method that runs on C<git flux feature start>.

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

