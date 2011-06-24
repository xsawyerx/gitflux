use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 4;

# TODO: tests with existing branch, tag

{
    my ($flux, $repo) = default_env();
    my $res = $flux->run(hotfix => 'start');
    ok !$res->is_success;
    like $res->error, qr/Missing argument <version>/;
}

{
    my ($flux, $repo) = default_env();
    my $res = $flux->run(hotfix => start => '1.0');
    ok $res->is_success;
    like $res->message, qr/Summary of actions/;
}
