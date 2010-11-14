#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Spec;
use File::Temp 'tempdir';
use Test::More tests => 11;
use Test::Fatal;
use TestFunctions;

{
    # if we can't find GITDIR, we init

    my $dir  = tempdir( CLEANUP => 1 );
    my $flux = Git::Flux->new( dir => $dir );

    chdir $dir;

    $flux->run('init');

    opendir my $dh, $dir    or die "Can't open dir '$dir': $!\n";
    my @files = readdir $dh or die "Can't read dir '$dir': $!\n";
    closedir $dh            or die "Can't close dir '$dir': $!\n";

    cmp_ok( scalar @files, '==', 3, 'Corrent number of files on init' );
    is_deeply( \@files, [qw/ .. .git . /], 'Corrent files/dirs created' );
}

{
    # TODO: the headless part... anyone?
    1;
}

{
    # requiring clean working directory
    my ( $flux, $repo ) = default_env();
    chdir $repo->work_tree;
    $flux->{repo} = $repo;
    
    my $file = File::Spec->catfile( $repo->work_tree, 'test' );
    open my $fh, '>', $file        or die "Can't open file '$file': $!\n";
    print {$fh} "blah blah blah\n" or die "Can't print to file '$file': $!\n";
    close $fh                      or die "Can't close file '$file': $!\n";

    is(
        exception { $flux->require_clean_working_tree },
        'fatal: Working tree contains unstaged changes. Aborting.',
        'require clean working directory (unstaged)',
    );

    $repo->run( add => $file );

    is(
        exception { $flux->require_clean_working_tree },
        'fatal: Index contains uncommited changes. Aborting.',
        'require clean working directory (uncommited)',
    );
}

{
    # init on existing repo without force
    # shouldn't work

    my ( $flux, $repo ) = default_env();

    is(
        exception { $flux->run('init') },
        "Already initialized for gitflux.\n" .
            "To force reinitialization, use: git flux init -f\n",
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

    my ( $flux, $repo ) = default_env();

    ok(
        ! exception { $flux->run( 'init' => '-f' ) },
        'reinit with force succeeds',
    );
}

{
    # TODO: when gitflux master isn't "master", it creates the new master branch
    1;
}

{
    # fresh git repo, branches will get created
    my ( $flux, $repo ) = default_env();

    # check that everything was created successfully
    is(
        $repo->run( config => '--get', 'gitflux.branch.master' ),
        'master',
        'master created',
    );

    foreach my $prefix ( qw/ feature release hotfix support / ) {
        is(
            $repo->run( config => '--get', "gitflux.prefix.$prefix" ),
            "$prefix/",
            "$prefix created",
        );
    }

    # FIXME: we need to find out the exit code of this instead of the value
    # because the value is by default blank, we don't know if it's configured
    # as empty or not configured at all - exit code gives us that
    is(
        $repo->run( config => '--get', 'gitflux.prefix.versiontag' ),
        'v',
        'versiontag created',
    );
}

# - renaming the branches before creation         = ok

