package Git::Flux::Command::feature;

use strict;
use warnings;
use mixin::with 'Git::Flux';

sub feature {
    my $self   = shift;
    my $cmd    = shift;
    my $method = "feature_$cmd";

    # dispatch to methods
    $self->$method(@_);
}

sub feature_start {
    my $self                = shift;
    my ( $br_name, $fetch ) = @_;
    my $repo                = $self->{'repo'};

    $br_name or die "Missing argument <name>\n";

    $self->require_branch_absent($br_name);

    # TODO: fetch flag handling

    # TODO: remove all hardcoding
    my $devel_br = 'devel';
    my $base     = $fetch || $devel_br;

    # if remote exists, compare them
    if ( $self->git_branch_exists("origin/$devel_br") ) {
        $self->require_branches_equal( $devel_br, "origin/$devel_br" );
    }

    # create branch
    my $result = $repo->command( checkout => '-b', $br_name => $base );
    $result->close();

    $result->exit == 0 or die "Could not create feature branch '$br_name'\n";

    print << "_END_REPORT";
Summary of actions:
- A new branch '$br_name' was created, based on '$base'
- You are now on branch '$br_name'

Now, start committing on your feature. When done, use:

     git flow feature finish $br_name
_END_REPORT

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

