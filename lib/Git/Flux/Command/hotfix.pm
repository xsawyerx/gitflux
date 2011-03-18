package Git::Flux::Command::hotfix;

use Mouse::Role;

# TODO
# list (-v): need tests
# start (-F version base):
# finish (-Fsumpk version):

sub hotfix {
    my $self = shift;
    my $cmd = shift || 'list';
    my $method = "hotfix_$cmd";

    $self->gitflux_load_settings();

    $self->$method(@_);
}

sub hotfix_list {
    my $self = shift;
    my $verbose = shift || 0;

    my $prefix = $self->hotfix_prefix();
    my @hotfix_branches = grep { /^$prefix/ } $self->git_local_branches();

    if (scalar @hotfix_branches == 0) {
        print << "__END_REPORT";
No hotfix branches exists

You can start a new hotfix branch:

    git flow hotfix start <name> [<base>]

__END_REPORT
        return;
    }

    my $current_branch = $self->git_current_branch();
    my $master_branch   = $self->{'master_branch'};
    my $repo = $self->{repo};

    foreach my $branch (@hotfix_branches) {
        my $base = $repo->run( 'merge-base' => $branch => $master_branch );
        my $master_sha = $repo->run('rev-parse' => $master_branch);
        my $branch_sha = $repo->run('rev-parse' => $branch);
        if ($branch eq $current_branch) {
            print '* ';
        }else{
            print ' ';
        }
        print "$branch\n";
    }
}

sub hotfix_start {
    my $self = shift;

    my $h_prefix = $self->hotfix_prefix;
    my $v_prefix = $self->version_prefix;

    my $version = shift || Carp::croak("Missing argument <version>");

    my $branch = $h_prefix . $version;
    my $tag    = $v_prefix . $version;

    my $base = shift || $self->{'master_branch'};
    $self->require_base_is_on_master( $base, $self->{'master_branch'} );
    $self->require_no_existing_hotfix_branches();

    $self->require_clean_working_tree();
    $self->require_branch_absent($branch);
    $self->required_tag_absent($tag);

    # TODO fetch

    my $repo = $self->{repo};
    $repo->run('checkout' => '-b' => $branch => $base);
    print << "__END_REPORT";

Summary of actions:
- A new branch '$branch' was created, based on '$base'
- You are now on branch '$branch'

Follow-up actions:
- Bump the version number now!
- Start committing your hot fixes
- When done, run:

    git flow hotfix finish '$version'

__END_REPORT
    
}

sub hotfix_finish {
    my $self = shift;

    my $version = pop || Carp::croak("Missing argument <version>");
    my $args = $self->parse_args(shift);

    my $h_prefix = $self->hotfix_prefix;
    my $v_prefix = $self->version_prefix;

    my $branch = $h_prefix . $version;
    my $tag    = $v_prefix . $version;

    $self->require_branch($branch);
    $self->require_clean_working_tree();

    my $origin = $self->{'origin_branch'};
    my $master = $self->{'master_branch'};
    my $devel  = $self->{'devel_branch'};

    my $repo = $self->{repo};
    my $res;

    if ( defined $args->{F} ) {
        $res = $repo->run( 'fetch' => '-q' => $origin => $master );
        $res->exit == 0 || Carp::croak("Could not fetch $master from $origin");

        $res = $repo->run( 'fetch' => '-q' => $origin => $devel );
        $res->exit == 0 || Carp::croak("Could not fetch $devel from $origin");
    }

    foreach my $br_name (qw/$master $devel/) {
        if ( grep { $_ eq $origin . "/" . $br_name }
            $self->git_remote_branches() )
        {
            $self->require_branches_equal( $br_name, $origin . "/" . $br_name );
        }
    }

    if ( !defined $args->{n} ) {
        if ( $self->git_tag_exists($tag) ) {
            # TODO sign
            my $res = $repo->run( 'tag' => $tag );
            $res->exit == 0
              || Carp::croak(
                "Tagging failed. Please run finish again to retry.");
        }
    }

    print << "__END_REPORT";

Summary of actions:
- Latest objects have been fetched from '$origin'
- Hotfix branch has been merged into '$master'
- The hotfix was tagger '$tag'
- Hotfix branch has been back-merged into '$devel'

__END_REPORT
    
}

sub require_no_existing_hotfix_branches {
    my ($self, $name) = @_;
    my $prefix = $self->hotfix_prefix();
    $self->require_not_existing_branches($prefix, $name);
}

1;

__END__

=head1 NAME

Git::Flux::Command::hotfix - hotfix command to Gitflux

=head1 DESCRIPTION

This provides hotfix branches functionality to Gitflux.

=head1 SUBROUTINES/METHODS

=head2 hotfix

Hotfixes can be started, finished, listed, etc.

=head2 hotfix_start

The method that runs on C<git flux hotfix start>.

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
