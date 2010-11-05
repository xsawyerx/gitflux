#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Temp 'tempdir';
use Test::More tests => 5;
use Test::Fatal;
use TestFunctions;

{
    # if we can't find GITDIR, we init

    my $dir  = tempdir( CLEANUP => 1 );
    my $flux = Git::Flux->new( dir => $dir );

    $flux->init;

    opendir my $dh, $dir    or die "Can't open dir '$dir': $!\n";
    my @files = readdir $dh or die "Can't read dir '$dir': $!\n";
    closedir $dh            or die "Can't close dir '$dir': $!\n";

    is_deeply(
        \@files,
        [ '.', '..', '.git' ],
        'init on non-git dir',
    );
}

{
    # TODO: the headless part... anyone?
    1;
}

{
    # requiring clean working directory

    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_dir );

    is(
        exception { $flux->init },
        'fatal: Working tree contains unstaged changes. Aborting.',
        'require clean working directory (unstaged)',
    );

    my $file = file( $repo->work_tree, 'test' );
    open my $fh, '>', $file        or die "Can't open file '$file': $!\n";
    print {$fh} "blah blah blah\n" or die "Can't print to file '$file': $!\n";
    close $fh                      or die "Can't close file '$file': $!\n";

    $repo->cmd( add => $file );

    is(
        exception { $flux->init },
        'fatal: Index contains uncommited changes. Aborting.',
        'require clean working directory (uncommited)',
    );
}

{
    # init on existing repo without force
    # shouldn't work

    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_dir );

    configure_default_repo($repo);

    is(
        exception { $flux->init },
        "Already initialized for gitflux\n" .
            'To force reinitialization, use: git flow init -f',
        'reinit without force fails',
    );
}

{
    # TODO: git flow isn't initialized if the master is the same as the develop
    1;
}

{
    # init on existing repo with force
    # should work

    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_tree );

    configure_default_repo($repo);

    ok(
        ! exception { $flux->init( force => 1 ) },
        'reinit with force succeeds',
    );
}

{
    # TODO: when gitflux master isn't "master", it creates the new master branch
    1;
}

{

}

# - initialize on dirty working tree              = not ok
# - creating all the correct branches             = ok
# - renaming the branches before creation         = ok

