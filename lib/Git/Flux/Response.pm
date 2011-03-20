package Git::Flux::Response;

use Mouse;

has message => (
    is  => 'rw',
    isa => 'Str',
);

has error => (
    is  => 'rw',
    isa => 'Str',
);

has status => (
    is  => 'rw',
    isa => 'Int',
);

1;
