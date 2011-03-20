#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Spec;
use File::Temp 'tempdir';
use Test::More;
use Test::Fatal;
use Test::TinyMocker;
use TestFunctions;
use Git::Repository;

plan skip_all => 'Default git binary not found in PATH'
    if !Git::Repository::Command::_is_git('git');

plan tests => 12;

{
    # remove interactive mode
    no warnings qw/redefine once/;
    *Git::Flux::is_interactive = sub {0};
}

{
    # TODO: the headless part... anyone?
    1;
}

{
    # requiring clean working directory
    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_tree );

    my $file = File::Spec->catfile( $repo->work_tree, 'test' );
    write_file( $file, "blah blah blah\n" );
    $repo->run( add => $file );
    $repo->run('commit' => '-m', 'test' );
    append_file( $file, "Dirty it up\n" );

    is(
        exception { $flux->run('init') },
        "fatal: Working tree contains unstaged changes. Aborting.\n",
        'require clean working directory (unstaged)',
    );

    $repo->run( add => $file );

    is(
        exception { $flux->run('init') },
        "fatal: Index contains uncommitted changes. Aborting.\n",
        'require clean working directory (uncommited)',
    );
}

{
    # init on existing gitflux repo without force
    # shouldn't work

    my $dir  = tempdir( CLEANUP => 1 );
    my $flux = Git::Flux->new( dir => $dir );
    $flux->run('init');

    is(
        exception { $flux->run('init') },
        "Already initialized for gitflux.\n" .
            "To force reinitialization, use: git flux init -f\n",
        'reinit without force fails',
    );
}

{
    # TODO: git flow isn't initialized if the master is the same as the devel
    1;
}

{
    # init on existing repo with force
    # should work

    my ( $flux, $repo ) = default_env();

    is(
        exception { $flux->run( 'init' => '-f' ) },
        undef,
        'reinit with force succeeds',
    );

    my $dir = $repo->work_tree;
    opendir my $dh, $dir    or die "Can't open dir '$dir': $!\n";
    my @files = readdir $dh or die "Can't read dir '$dir': $!\n";
    closedir $dh            or die "Can't close dir '$dir': $!\n";

    cmp_ok( scalar @files, '==', 4, 'Corrent number of files on init' );

    is_deeply(
        [ sort @files],
        [qw/ . .. .git README /],
        'Corrent files/dirs created',
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
    my $cmd = $repo->command( config => qw/ --get gitflux.prefix.versiontag / );
    $cmd->close;

    cmp_ok( $cmd->exit, '==', 0, 'versiontag created' );
}

