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

    # got master, develop configured
    $repo->cmd( config => 'gitflux.branch.master',  'master'  );
    $repo->cmd( config => 'gitflux.branch.develop', 'develop' );

    # has prefixes configured for every branch
    # (feature, release, hotfix, support)
    foreach my $prefix ( qw/ feature release hotfix support / ) {
        $repo->cmd( config => "gitflux.prefix.$prefix", "$prefix/" );
    }

    # versiontag configured
    $repo->cmd( config => 'gitflux.prefix.versiontag', 'v' );

    is(
        exception { $flux->init },
        'Already initialized for gitflux',
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

    # got master, develop configured
    $repo->cmd( config => 'gitflux.branch.master',  'master'  );
    $repo->cmd( config => 'gitflux.branch.develop', 'develop' );

    # has prefixes configured for every branch
    # (feature, release, hotfix, support)
    foreach my $prefix ( qw/ feature release hotfix support / ) {
        $repo->cmd( config => "gitflux.prefix.$prefix", "$prefix/" );
    }

    # versiontag configured
    $repo->cmd( config => 'gitflux.prefix.versiontag', 'v' );

    ok(
        ! exception { $flux->init( force => 1 ) },
        'reinit with force succeeds',
    );
}

# - initialize on dirty working tree              = not ok
# - creating all the correct branches             = ok
# - renaming the branches before creation         = ok

