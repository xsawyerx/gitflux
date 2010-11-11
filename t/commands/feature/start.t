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

    my ( $flux, $repo ) = default_env();

    is(
        exception { $flux->run( feature => 'start' ) },
        "Missing argument <name>\n",
        'Cannot init without name',
    );
}

{
    # if branch name exists, we die

    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    # create feature branch
    $repo->run( branch => $branch );

    is(
        exception { $flux->run( feature => 'start', $branch ) },
        qq{Branch '$branch' already exists. Pick another name.\n},
        'Cannot create feature branch with pre-existing name',
    );
}

{
    # fetch flag
    1;
}

{
    # assert origin's same-name branch isn't behind it

    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    # create origin feature branch, at least fooling the app to think so
    $repo->run( branch => "origin/$branch" );

    # this shouldn't be a problem since it isn't really origin,
    # just looks like
    ok(
        ! exception { $flux->run( feature => 'start', $branch ) },
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

    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    # cripple branch creation so it doesn't work
    mock 'Git::Repository::Command'
        => method 'run'
        => should {
            my $self = shift;
            my $run = shift;
            return;
        };

    is(
        exception { $flux->run( feature => 'start', $branch ) },
        qq{Could not create feature branch '$branch'\n},
        'Recognizing git branch failure',
    );

    unmock 'Git::Repository::Command' => method 'run';
}

{
    # everything working

    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    ok(
        ! exception { $flux->run( feature => 'start', $branch ) },
        'feature start command lives',
    );

    ok(
        $flux->_branch_exists($branch),
        'branch was created successfully',
    );
}

