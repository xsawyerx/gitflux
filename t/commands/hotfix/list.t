use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 7;

{
    my ($flux, $repo) = default_env();
    my $res = $flux->run(hotfix => 'list');
    ok !$res->is_success;
    like $res->error, qr/No hotfix branches exists/;
}

{
    # listing existing features
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'hotfix/foo');
    $repo->run(branch => 'hotfix/bar');
    $repo->run(branch => 'devel');
    my $res = $flux->run(hotfix => 'list');
    ok $res->is_success;
    like $res->message, qr!hotfix/foo!;
    like $res->message, qr!hotfix/bar!;
}

{
    # listing existing features, when one of them is the current branch
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'hotfix/bar');
    $repo->run(branch => 'devel');
    $repo->command(checkout => 'hotfix/bar');
    my $res = $flux->run(hotfix => 'list');
    ok $res->is_success;
    like $res->message, qr!\* hotfix/bar!;
}

