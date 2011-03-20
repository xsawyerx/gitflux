package Git::Flux::Term;

use Mouse::Role;
use Term::Readline;

has term => (
    is      => 'rw',
    isa     => 'Term::Readline',
    lazy    => 1,
    default => sub {
        my $term = Term::Readline->new('Gitflux');
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
