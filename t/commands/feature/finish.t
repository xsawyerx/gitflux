use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::More;

plan tests => 4;

{
    my ( $flux, $repo ) = default_env();
    my $dir = $repo->work_tree;

    chdir $dir;

    $flux->run('init');
    $flux->run(feature => start => 'test');
    write_file( 'CHANGES', 'this is our changelog' );
    $repo->run(add => 'CHANGES');
    $repo->run( commit => '-m' => 'changelog' );
    my $res = $flux->run( feature => 'finish' => 'test' );
    like $res->message, qr/Summary of actions/;

    my @branches = $flux->git_local_branches();
    is scalar @branches, 2;
    my @out = $repo->run(log => '--oneline');
    is scalar @out, 3;
    like $out[0], qr/Merge branch 'feature\/test'/;
}
