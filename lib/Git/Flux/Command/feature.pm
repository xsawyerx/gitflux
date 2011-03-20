package Git::Flux::Command::feature;

use Mouse::Role;
use File::Spec;
use Carp;

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

    # dispatch to methods
    $self->$method(@_);
}

sub feature_start {
    my $self = shift;
    my $name = shift; 
    my $base = shift || $self->devel_branch;
    
    my $repo = $self->repo;

    die "Missing argument <name>" if ( !$name );

    $name = $self->expand_nameprefix($name);
    $self->require_branch_absent($name);

    # TODO: handle fetch flag handling

    my $devel_br = $self->devel_branch;
    my $origin   = $self->origin;

    # if remote exists, compare them
    if ( $self->git_branch_exists("$origin/$devel_br") ) {
        $self->require_branches_equal( $devel_br, "$origin/$devel_br" );
    }

    # create branch
    my $result = $repo->command( checkout => '-b' => $name => $base );
    $result->close;

    my $res = $repo->command( checkout => '-b' => $name );
    if ( $res->exit && $res->exit > 0 ) {
        Carp::croak "Could not create feature branch `$name'";
    }
    
    my $message = <<'_END';
Summary of actions:
- A new branch '$name' was created, based on '$base'
- You are now on branch '$name'

Now, start committing on your feature. When done, use:

     git flow feature finish $name

_END

    return $message;
}

sub feature_list {
    my $self = shift;

    my $repo   = $self->repo;
    my $prefix = $self->feature_prefix();

    my @features_branches = grep { /^$prefix/ } $self->git_local_branches();

    if ( !scalar @features_branches ) {
        my $error = << '_END';
No feature branches exists.

You can start a new feature branch:

    git-flux feature start <name> [<base>]

_END
        die $error;
    }

    my $current_branch = $self->git_current_branch();
    my $devel_branch   = $self->devel_branch;

    my $message = '';
    foreach my $branch (@features_branches) {
        $message .= $branch eq $current_branch ? '* ' : ' ';
        $message .= "$branch\n";
    }

    return $message;
}

sub feature_track {
    my ( $self, $name ) = @_;

    die "Missing argument <name>" if ( !$name );

    $name = $self->expand_nameprefix($name);

    $self->require_clean_working_tree();
    $self->require_branch_absent($name);

    my $repo = $self->repo;
    my $origin = $self->origin;

    my $cmd = $repo->command( 'fetch' => '-q' => $origin );
    my $err = $cmd->stderr->getline;
    $cmd->close;
    die $err if ( $cmd->exit != 0 );

    my $origin_br = $origin . '/' . $name;
    $self->require_branch($origin_br);

    $cmd = $repo->command( 'checkout' => '-b' => $name => $origin_br );
    $err = $cmd->stderr->getline;
    $cmd->close;
    die $err if ( $cmd->exit != 0 );

    my $message = << '_END';

Summary of actions:
- A new remote tracking branch '$name' was created
- You are now on branch '$name'

_END

    return $message;
}

sub feature_pull {
    my $self   = shift;
    my $remote = shift;

    die "Name a remote explicitly" if ( !$remote );

    my $current_branch = $self->git_current_branch();
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

    my $repo = $self->repo;

    if ( $self->git_branch_exists($name) ) {
        $self->_avoid_accidental_cross_branch_action($name)
          || die "Die (?)";

        my $res = $repo->run( 'pull' => '-q' => $remote => $name );
        die "Failed to pull from remote `$remote'";

        $res = $repo->run( 'fetch' => "-q" => $remote => $name );
        $res->exit == 0 || die "Fetch failed";

        $res = $repo->run( 'branch' => '--no-track' => $name => "FETCH_HEAD" );
        $res->exit == 0 || die "Branch failed";

        $res = $repo->run( 'checkout' => "-q" => $name );
        $res->exit == 0
          || die "Checking out new local branch failed";
        print "Created local branch $name based on $remote's $name\n";
        return;
    }

    my $res = $repo->run( 'fetch', => "-q" => $remote => $name );
    $res->exit == 0 || die "Fetch failed";

    $res = $repo->run( 'branch' => '--no-track' => $name => "FETCH_HEAD" );
    $res->exit == 0 || die "Branch failed";

    $res = $repo->run( 'checkout', '-q', $name );
    $res->exit == 0 || die "Checking out new local branch failed";
    print "Created local branch $name based on $remote's branch\n";
}

sub feature_checkout {
    my ( $self, $name ) = @_;

    die "Name a feature branch explicitly" if ( !$name );

    $name = $self->expand_nameprefix($name);
    my $cmd = $self->{repo}->command( 'checkout' => $name );
    my $err = $cmd->stderr->getline;
    $cmd->close;
    die $err if ( $cmd->exit != 0 );
    return 1;
}

sub feature_diff {
    my $self = shift;
    my $name = shift;

    my $repo   = $self->repo;
    my $prefix = $self->feature_prefix();
    my $devel  = $self->devel_branch;

    if ( !defined $name ) {
        my $current_branch = $self->git_current_branch();
        die "Not on a feature branch. Name one explicitly" if ( $current_branch !~ /^$prefix/ );
        my $base = $repo->run( 'merge-base' => $current_branch => "HEAD" );
        my $res = $repo->run( 'diff' => $base );
        return 1;
    }

    $name = $self->expand_nameprefix($name);

    my $base = $repo->run( 'merge-base' => $self->devel_branch => $name );
    $repo->run( 'diff' => "$base..$name" );
    return 1;
}

sub feature_publish {
    my ( $self, $name ) = @_;

    $self->expand_nameprefix($name);

    my $repo   = $self->repo;
    my $origin = $self->origin;

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

    my $message = << '_END';
Summary of actions:
- A new remote branch '$name' was created
- The local branch '$name' was configured to track the remote branch
- You are now on branch '$name'

_END
    
    return $message;
}

sub feature_rebase {
    my $self = shift;

    my ( $interactive, $name );

    if ( @_ == 2 ) {
        $interactive = shift;
    }
    $name = $self->expand_nameprefix(shift);

    $self->require_clean_working_tree();
    $self->require_branch($name);

    my $repo = $self->repo;
    $repo->run( 'checkout' => "-q" => $name );

    my @opts;
    push @opts, "-i" if $interactive;
    push @opts, $self->devel_branch;
    $repo->run( 'rebase' => @opts );
    return 1;
}

sub feature_finish {
    my $self = shift;
    my $name = $self->expand_nameprefix(shift);

    # TODO handle fetch and rebase flag

    $self->require_branch($name);

    # TODO detect if we're restoring from a merge conflict
    
    $self->require_clean_working_tree();

    my $origin = $self->origin;
    my $devel = $self->devel_branch;
    my @remotes_branches = $self->git_remote_branches;

    if ( grep { $_ eq $origin . "/" . $name } @remotes_branches ) {
        # XXX if rebase flag
        # $self->repo->run( 'fetch' => '-q' => $origin => $name );
        $self->require_branches_equal( $name, $origin . "/" . $name );
    }

    if ( grep { $_ eq $origin . "/" . $devel } @remotes_branches ) {
        $self->require_branches_equal( $name, $origin . "/" . $devel );
    }

    # TODO do we want to rebase ?

    my $res = $self->repo->command('checkout' => $devel);

    $res = $self->repo->command('merge' => '--no-ff' =>  $name);
    if ($res->exit && $res->exit > 0) {
        my $path = File::Spec->catdir($self->repo->git_dir, '.gitflux');

        mkdir File::Spec->catdir($path);
        open my $fh, '>', File::Spec->catfile($path, 'MERGE_BASE');
        print $fh $devel;
        close $fh;

        my $message = << '_END';

There were merge conflicts. To resolve the merge conflict manually, use:
    git mergetool
    git commit

You can then complete the finish by running it again:
    git flow feature finish $name

_END

        return $message;
    }

   $self->repo->run('branch' => '-d' => $name);

    my $message = << "_END";

Summary of actions:

- The feature branch '$name' was merged into '$devel'
- Feature branch '$name' has been removed
- You are now on branch '$devel'

_END

    return $message;
}

sub _avoid_accidental_cross_branch_action {
    my ( $self, $name ) = @_;
    my $current_br = $self->git_current_branch();
    if ( $current_br ne $name ) {
        warn "Trying to pull from $name while currently on branch '$current_br'.\n";
        warn "To avoid unintended merges, git-flow aborted.\n";
        return 0;
    }
    return 1;
}

sub expand_nameprefix {
    my ( $self, $name ) = @_;
    my $prefix = $self->feature_prefix();
    $self->expand_prefix( $prefix, $name );
}


sub _feature_end {1}

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

=head2 feature_list

The method that runs on C<git flux feature list>. (This is the default command)

=head2 feature_track

The method that runs on C<git flux feature track>.

=head2 feature_pull

The method that runs on C<git flux feature pull>.

=head2 feature_checkout

The method that runs on C<git flux feature checkout>.

=head2 feature_diff

The method that runs on C<git flux feature diff>.

=head2 feature_publish

The method that runs on C<git flux feature publish>.

=head2 feature_rebase

The method that runs on C<git flux feature rebase>.

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

