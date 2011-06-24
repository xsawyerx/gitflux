use strict;
use warnings;

use lib 't/lib';
use Git::Flux;
use TestFunctions;

use Test::Git;
use Test::More;

has_git;

plan tests => 6;

{
    # testing with no name
    my ($flux, $repo) = default_env();
    my $res = $flux->run(feature=> 'track');
    ok !$res->is_success;
    like $res->error, qr/Missing argument <name>/;
}

{
    # origin doesn't exists
    my ($flux, $repo) = default_env();
    my $res = $flux->run('feature' => 'track' => 'foo');
    ok !$res->is_success;
    like $res->error, qr/fatal: 'origin' does not appear to be a git repository/;
}

{
    # with origin
    my ($flux, $repo) = default_env();
    my $orig = cwd();

    my $dir = tempdir( CLEANUP => 1 );
    chdir $dir or die "Can't chdir back to $dir: $!";
    Git::Repository->run('init');
    my $orig_repo = Git::Repository->new;
    write_file( 'README', '' );
    $orig_repo->run( add => 'README' );
    $orig_repo->run( commit => '-m', 'initializing gitflux' );
    $orig_repo->run( branch => 'feature/test');
    chdir $orig or die "Can't chdir back to $orig: $!";

    $repo->run(remote => add => origin => $dir);

    my $res = $flux->run('feature' => 'track' => 'test');
    ok $res->is_success;
    like $res->message, qr/Summary of actions/;
}
