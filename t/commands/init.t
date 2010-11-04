#!perl

# what we need to test:
# - creating gitflux on already initialized repo  = ok
# - creating gitflux with pre-existing branches   = not ok
# - being able to use 'force' to enable last case = ok
# - initialize on dirty working tree              = not ok
# - creating all the correct branches             = ok
# - renaming the branches before creation         = ok

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use Test::More tests => 5;
use Test::Fatal;
use TestFunctions;

my $flux = Git::Flux->new;

