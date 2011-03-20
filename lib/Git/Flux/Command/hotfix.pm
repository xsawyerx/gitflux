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

    $self->$method(@_);
}

sub hotfix_list {
    my $self = shift;
    my $verbose = shift || 0;

    my $prefix = $self->hotfix_prefix();
    my @hotfix_branches = grep { /^$prefix/ } $self->git_local_branches();

    if ( scalar @hotfix_branches == 0 ) {
        my $msg = qq{
No hotfix branches exists

You can start a new hotfix branch:

    git flow hotfix start <name> [<base>]

};
        die $msg;
    }

    my $current_branch = $self->git_current_branch();
    my $master_branch   = $self->master_branch;
    my $repo = $self->repo;

    my $message = '';
    foreach my $branch (@hotfix_branches) {
        $message .= $branch eq $current_branch ? '* ' : ' ';
        $message .= "$branch\n";
    }
    return $message;
}

sub hotfix_start {
    my $self = shift;

    my $h_prefix = $self->hotfix_prefix;
    my $v_prefix = $self->version_prefix;

    my $version = shift || die "Missing argument <version>\n";

    my $branch = $h_prefix . $version;
    my $tag    = $v_prefix . $version;

    my $base = shift || $self->master_branch;
    $self->require_base_is_on_master( $base, $self->master_branch );
    $self->require_no_existing_hotfix_branches();

    $self->require_clean_working_tree();
    $self->require_branch_absent($branch);
    $self->require_tag_absent($tag);

    # TODO fetch

    my $repo = $self->repo;
    $repo->run('checkout' => '-b' => $branch => $base);
    my $message = qq{

Summary of actions:
- A new branch '$branch' was created, based on '$base'
- You are now on branch '$branch'

Follow-up actions:
- Bump the version number now!
- Start committing your hot fixes
- When done, run:

    git flow hotfix finish '$version'

};
    return $message;
}

sub hotfix_finish {
    my $self = shift;

    my $version = pop || die "Missing argument <version>\n";

    my $args = $self->parse_args(shift);

    my $h_prefix = $self->hotfix_prefix;
    my $v_prefix = $self->version_prefix;

    my $branch = $h_prefix . $version;
    my $tag    = $v_prefix . $version;

    $self->require_branch($branch);
    $self->require_clean_working_tree();

    my $origin = $self->origin;
    my $master = $self->master_branch;
    my $devel  = $self->devel_branch;

    my $repo = $self->repo;
    my $res;

    if ( defined $args->{F} ) {
        my $cmd = $repo->command( 'fetch' => '-q' => $origin => $master );
        $cmd->close;
        $cmd->exit == 0 || die "Could not fetch $master from $origin\n";

        $cmd = $repo->command( 'fetch' => '-q' => $origin => $devel );
        $cmd->close;
        $cmd->exit == 0 || die "Could not fetch $devel from $origin\n";
    }

    foreach my $br_name (qw/$master $devel/) {
        if ( grep { $_ eq $origin . "/" . $br_name }
            $self->git_remote_branches() )
        {
            $self->require_branches_equal( $br_name, $origin . "/" . $br_name );
        }
    }

    if ( !defined $args->{n} ) {
        if ( !$self->git_tag_exists($tag) ) {
            # TODO sign
            my $cmd = $repo->command( 'tag' => $tag );
            $cmd->close;
            $cmd->exit == 0 || die "Tagging failed. Please run finish again to retry.\n";
        }
    }

    my $message = qq{

Summary of actions:
- Latest objects have been fetched from '$origin'
- Hotfix branch has been merged into '$master'
- The hotfix was tagger '$tag'
- Hotfix branch has been back-merged into '$devel'

};
    return $message;
}

sub require_no_existing_hotfix_branches {
    my ($self, $name) = @_;
    my $prefix = $self->hotfix_prefix();
    $self->require_no_existing_branches($prefix, $name);
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

=head2 hotfix_list

The method that runs on C<git flux hotfix list>. (This is the default command)

=head2 hotfix_finish

The method that runs on C<git flux hotfix finish>.

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
