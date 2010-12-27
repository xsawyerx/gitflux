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

sub feature {
    my $self = shift;
    my $cmd = shift || 'list';

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

    my $prefix  = $self->feature_prefix();
    my $br_name = $prefix . $name;

    $self->require_branch_absent($br_name);

    # TODO: handle fetch flag handling

    my $devel_br = $self->{devel_branch};
    my $origin   = $self->{origin_branch};

    # if remote exists, compare them
    if ( $self->git_branch_exists("$origin/$devel_br") ) {
        $self->require_branches_equal( $devel_br, "$origin/$devel_br" );
    }

    # create branch
    my $result = $repo->command( checkout => '-b' => $br_name => $base );
    $result->exit == 0
      or Carp::croak "Could not create feature branch '$br_name'";

    print << "_END_REPORT";
Summary of actions:
- A new branch '$br_name' was created, based on '$base'
- You are now on branch '$br_name'

Now, start committing on your feature. When done, use:

     git flow feature finish $br_name
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
    my $self = shift;
    my $remote = shift;

    if ( !$remote ) {
        Carp::croak("Name a remote explicitly");
    }

    $current_branch = $self->git_current_branch();
    my $prefix = $self->feature_prefix();

    my $name = shift || $current_branch;

    # To avoid accidentally merging different feature branches into each
    # other, die if the current feature branch differs from the requested
    # $NAME argument.
    # XXX test with avoid_accidental...
    if ($current_branch =~ /^$prefix/) {
        $self->_avoid_accidental_cross_branch_action();        
    }

    $self->require_clean_working_tree();

    my $repo = $self->{repo};
    if ( $self->git_branch_exists($branch) ) {

        $self->_avoid_accidental_cross_branch_action();
        $repo->run( 'pull' => qw/-q $remote $branch/ )
          || die "Failed to pull from remote '$remote'";
        print "Pulled $remote's changes into $branch\n";
        $repo->run( 'fetch' => "-q", $remote, $branch ) || die "Fetch failed";
        $repo->run( 'branch' => qw/--no-track/, $branch, "FETCH_HEAD" )
          || die "Branch failed";
        $repo->run( 'checkout' => "-q", $branch )
          || die "Checking out new local branch failed";
        print "Created local branch $branch based on $remote's $branch\n";
    }
    else {
        $repo->run( 'fetch', => "-q", $remote, $branch ) || die "Fetch failed";
        $repo->run( 'branch' => qw/--no-track/, $branch, "FETCH_HEAD" )
          || die "Branch failed";
        $repo->run( 'checkout', '-q', $branch )
          || die "Checking out new local branch failed";
        print "Created local branch $branch based on $remote's branch\n";
    }
}

sub feature_checkout {
    my ( $self, $name ) = @_;

    my $repo = $self->{repo};

    if ( defined $name ) {
        my $branch_name = $self->prefix . $name;
        $repo->run( 'checkout' => $branch_name );
    }
    else {
        Carp::croak "Name a feature branch explicitly";
    }
}

sub feature_diff {
    my $self = shift;

    my $name;
    if (@_ == 1) {
        $name = shift;
    }

    my $branch; my $devel;
    my $repo = $self->{repo};
    if (defined $name) {
        my $base = $repo->run('merge-base', $self->{devel_branch}, $branch);
        $repo->run('diff' => qw/$base..$branch/);
    }else{
        my $current_branch = $self->current_branch();
        my $prefix = $self->prefix;
        if ($current_branch !~ /^$prefix/) {
            Carp::croak("Not on a feature branch. Name one explicitly");
        }
        my $base = $repo->run('merge-base', $devel, "HEAD");
        $repo->run('diff' => $base);
    }
}

sub feature_publish {
    my ($self, $name) = @_;

    my $repo = $self->{repo};

    $self->require_clean_working_tree();
    my $origin = $self->{origin_branch};
    # XXX require_branch
    $repo->run('fetch' => "-q", $origin);

    my $br_name;
    my $prefix = $self->prefix();
    $br_name = $prefix . $br_name;
    $self->require_branch_absent($br_name);

    # create remote branch
    $repo->run('push', $origin, "$br_name:refs/heads/$br_name");
    $repo->run('fetch', "-q", $origin);

    # configure remote tracking
    $repo->run('config', "branch.$br_name.remote", $origin);
    $repo->run('config', "branch.$br_name.merge", "refs/head/$br_name");
    $repo->run('checkout', $br_name);

    print << "_END_REPORT";
Summary of actions:
- A new remote branch '$br_name' was created
- The local branch '$br_name' was configured to track the remote branch
- You are now on branch '$br_name'

_END_REPORT
    
}

sub feature_rebase {
    my $self = shift;

    my ( $interactive, $name ) = @_;
    if ( @_ == 2 ) {
        $interactive = shift;
        $name        = shift;
    }
    elsif ( @_ == 1 ) {
        $name = shift;
    }

    my $branch;

    warn "Will try to rebase '$name'...";
    $self->require_clean_working_tree();
    $self->require_branch($branch);

    my $repo = $self->{repo};
    $repo->run( 'checkout', "-q", $branch );
    my @opts;
    if ($interactive) {
        push @opts, "-i";
    }
    push @opts, $self->{devel_branch};
    $repo->run( 'rebase' => @opts );
}

sub _avoid_accidental_cross_branch_action {
    my $self = shift;
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

