package Git::Flux::Term;

use Mouse::Role;
use Term::ReadLine;

has term => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my $term = Term::ReadLine->new('Gitflux');
        $term->ornaments(0);
        $term;
    },
);

sub is_interactive {
    return -t STDIN && -t STDOUT;
}

sub answer {
    my ( $self, $prompt, $default_suggestion ) = @_;

    my $answer =
        $self->is_interactive
      ? $self->term->readline($prompt)
      : $default_suggestion;
}

1;

=head1 NAME

Git::Flux::Term

=head1 DESCRIPTION

=head1 METHODS

=head2 is_interactive

Returns boolean on whether we're in interactive mode.
