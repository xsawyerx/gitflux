package Git::Flux::Command::help;

use Mouse::Role;

sub help {
    my $self = shift;
    print << '_END_HELP';
Gitflux help

... doesn't exist yet!
_END_HELP

    exit 0;
}

1;

__END__

=head1 NAME

Git::Flux::Command::help - help command to Gitflux

=head1 DESCRIPTION

This provides Gitflux with a help output.

=head1 SUBROUTINES/METHODS

=head2 help

Print a help output.

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

