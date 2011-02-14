package Git::Flux::Command::hotfix;

use Mouse::Role;

sub hotfix {
    my $self   = shift;
    my $cmd    = shift;
    my $method = "feature_$cmd";
    my $repo   = $self->{repo};

    $self->require_git_repo;
    $self->require_gitflux_initialized;
    $self->gitflux_load_settings;

    $self->{'prefix'}{'version'} = $repo->run(
        config => qw/ --get gitflux.prefix.versiontag /
    );

    $self->{'prefix'}{'hotfix'} = $repo->run(
        config => qw/ --get gitflux.prefix.hotfix /
    );

    # dispatch to methods
    $self->$method(@_);
}

sub hotfix_help {
    print << '_END_HELP';
usage: git flow hotfix [list] [-v]
       git flow hotfix start [-F] <version> [<base>]
       git flow hotfix finish [-Fsumpk] <version>
_END_HELP

    exit 0;
}

sub hotfix_start {
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

