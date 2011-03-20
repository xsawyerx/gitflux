use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::More;

plan tests => 5;

{
    # testing with no name
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'diff');
    ok !$res->is_success;
    like $res->error, qr/Not on a feature branch/;
}

{
    # testing with no name on a feature branch
    my ( $flux, $repo ) = default_env();
    $repo->run( branch   => 'devel' );
    $repo->run( branch   => 'feature/test' );
    $repo->command( checkout => 'feature/test' );
    my $res = $flux->run( feature => 'diff' );
    ok $res->is_success;
}

{
    # testing with name
    my ($flux, $repo) = default_env();
    $repo->run(branch => 'devel');
    $repo->run(branch => 'feature/test');
    my $res = $flux->run(feature => 'diff' => 'test');
    ok $res->is_success;
}

{
    # testing with name and diff
    my ($flux, $repo) = default_env();
    my $dir = $repo->work_tree;
    chdir $dir;
    $repo->run(branch => 'devel');
    $repo->run(branch => 'feature/test');
    $repo->command(checkout => 'feature/test');
    write_file('CHANGES', 'this is the changelog');
    $repo->run(add => 'CHANGES');
    $repo->run(commit => '-m' => 'adding changelog');
    my $res = $flux->run(feature => 'diff');
    ok $res->is_success;
}
