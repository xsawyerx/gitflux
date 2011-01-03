use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::More;

plan tests => 7;

{
    # testing when no features exist
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'list');
    ok !$res->is_success;
    like $res->error, qr/No feature branches exists/;
}

{
    # listing existing features
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'feature/foo');
    $repo->run(branch => 'feature/bar');
    $repo->run(branch => 'devel');
    my $res = $flux->run(feature => 'list');
    ok $res->is_success;
    like $res->message, qr!feature/foo!;
    like $res->message, qr!feature/bar!;
}

{
    # listing existing features, when one of them is the current branch
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'feature/bar');
    $repo->run(branch => 'devel');
    $repo->command(checkout => 'feature/bar');
    my $res = $flux->run(feature => 'list');
    ok $res->is_success;
    like $res->message, qr!\* feature/bar!;
}
