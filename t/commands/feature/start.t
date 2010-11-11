#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Temp 'tempdir';
use Test::More tests => 6;
use Test::Fatal;
use TestFunctions;
use Test::TinyMocker;

{
    # can't init without name

    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_dir );

    configure_default_repo();

    is(
        exception { $flux->cmd( feature => 'start' ) },
        'Missing argument <name>',
        'Cannot init without name',
    );
}

{
    # if branch name exists, we die

    my $repo   = create_empty_repo();
    my $flux   = Git::Flux->new( dir => $repo->work_dir );
    my $branch = 'test_feature';

    configure_default_repo();

    # create feature branch
    $repo->cmd( branch => $branch );

    is(
        exception { $flux->cmd( feature => 'start', $branch ) },
        qq{Branch '$branch' already exists. Pick another name.},
        'Cannot create feature branch with pre-existing name',
    );
}

{
    # fetch flag
    1;
}

{
    # assert origin's same-name branch isn't behind it

    my $repo   = create_empty_repo();
    my $flux   = Git::Flux->new( dir => $repo->work_dir );
    my $branch = 'test_feature';

    configure_default_repo();

    # create origin feature branch, at least fooling the app to think so
    $repo->cmd( branch => "origin/$branch" );

    # this shouldn't be a problem since it isn't really origin,
    # just looks like
    ok(
        ! exception { $flux->cmd( feature => 'start', $branch ) },
        'No problem on differing branches',
    );
}

{
    # assert origin's same-name branch isn't behind it
    # when in fact it is
    # this requires to actually create a remote branch
    1;
}

{
    # exception thrown when cannot create branch

    my $repo   = create_empty_repo();
    my $flux   = Git::Flux->new( dir => $repo->work_dir );
    my $branch = 'test_feature';

    configure_default_repo();

    # cripple branch creation so it doesn't work
    mock 'Git::Repository::Command'
        => method 'run'
        => should {
            my $self = shift;
            my $cmd = shift;
            return;
        };

    is(
        exception { $flux->cmd( feature => 'start', $branch ) },
        qq{Could not create feature branch '$branch'},
        'Recognizing git branch failure',
    );

    unmock 'Git::Repository::Command' => method 'run';
}

{
    # everything working

    my $repo   = create_empty_repo();
    my $flux   = Git::Flux->new( dir => $repo->work_dir );
    my $branch = 'test_feature';

    configure_default_repo();

    ok(
        ! exception { $flux->cmd( feature => 'start', $branch ) },
        'feature start command lives',
    );

    ok(
        $flux->_branch_exists($branch),
        'branch was created successfully',
    );
}
