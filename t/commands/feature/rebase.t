use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 1;

{
    my ( $flux, $repo ) = default_env();
    my $dir = $repo->work_tree;

    chdir $dir;

    $repo->run( branch => 'devel' );
    $repo->run( branch => 'feature/test' );
    $repo->command( checkout => 'devel' );

    write_file( 'CHANGES', 'this is our changelog' );

    $repo->run( commit => '-m' => 'changelog' );
    $repo->command( checkout => 'feature/test' );

    my $res = $flux->run( feature => 'rebase' => 'test' );
    ok $res->is_success;
}

