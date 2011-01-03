use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::More;

plan tests => 3;

# TODO: tests with existing branch, tag

{
    my ($flux, $repo) = default_env();
    my $res = $flux->run(hotfix => 'finish');
    ok !$res->is_success;
    like $res->error, qr/Missing argument <version>/;
}

{
    my ($flux, $repo) = default_env();
    $flux->run(hotfix => start => '1.0');
    my $res = $flux->run(hotfix => 'finish' => '1.0');
    ok $res->is_success;
}