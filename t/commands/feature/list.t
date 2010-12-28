use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;
use Test::TinyMocker;

use Test::More;

plan tests => 2;

{
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'list');
}

{
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'feature/foo');
    $repo->run(branch => 'feature/bar');
    $flux->run(feature => 'list');
}
