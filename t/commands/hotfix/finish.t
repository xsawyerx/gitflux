use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 5;

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
    like $res->message, qr/Summary of actions/;
    $res = $repo->command('tag');
    my $tag = $res->stdout->getline;
    $res->close();
    like $tag, qr/1\.0/;
}
