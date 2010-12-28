#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Temp 'tempdir';
use Test::More;
use TestFunctions;
use Test::TinyMocker;

plan tests => 11;

{

    # can't init without name
    my ( $flux, $repo ) = default_env();
    my $res = $flux->run( feature => 'start' );
    ok !$res->is_success;
    like $res->error, qr/Missing argument <name>/, 'Cannot init without name',
}

{

    # if branch name exists, we die
    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    # create feature branch
    $repo->run( branch => "feature/" . $branch );

    my $res = $flux->run( feature => 'start', $branch );
    ok !$res->is_success;
    like $res->error,
      qr/Branch 'feature\/$branch' already exists. Pick another name/,
      'Cannot create feature branch with pre-existing name',
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
    my $res = $flux->run( feature => 'start', $branch );
    ok $res->is_success;
    like $res->message, qr/Summary of actions/;
}

{
    # assert origin's same-name branch isn't behind it
    # when in fact it is
    # this requires to actually create a remote branch
    1;
}

{
    # exception thrown when cannot create branch
    {

        package Ztest;
        sub close { 1 }
        sub exit  { 255 }
    }
    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    # cripple branch creation so it doesn't work
    mock 'Git::Repository' => method 'command' => should {
        return bless {}, 'Ztest';
    };

    my $res = $flux->run( feature => 'start', $branch );
    ok !$res->is_success;
    like $res->error,
      qr/Could not create feature branch 'feature\/$branch'/,
      'Recognizing git branch failure';

    unmock 'Git::Repository' => method 'command';
}

{
    # everything working

    my ( $flux, $repo ) = default_env();
    my $branch = 'test_feature';

    my $res =  $flux->run( feature => 'start', $branch );
    ok ($res->is_success, "feature start command lives");
    like $res->message, qr/Summary of actions/;
    ok $flux->git_branch_exists('feature/'.$branch),
      'branch was created successfully';
}
