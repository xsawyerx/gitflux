use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 5;

{
    # testing with no name
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'checkout');
    ok !$res->is_success;
    like $res->error, qr/Name a feature branch explicitly/;
}

{
    # testing when repo doesn't exists
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'checkout' => 'test');
    ok !$res->is_success;
    like $res->error, qr/did not match any file\(s\) known to git/;
}

{
    # testing when repo exists
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'feature/test');
    my $res = $flux->run(feature=> 'checkout' => 'test');
    ok $res->is_success;
}
