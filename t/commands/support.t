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
    # list if no support branches exist
    # should fail

    my ( $flux, $repo ) = default_env();

    is(
        exception { $flux->cmd('list') },
        'fatal: Not a gitflux-enabled repo yet. ' .
            'Please run "git flux init" first.',
        'support list without branches fails',
    );
}

{
    # list when gitflux initialized
    # should work

    my ( $flux, $repo ) = default_env();

    my $output = <<'_END';
note: The support subcommand is still very EXPERIMENTAL!
note: DO NOT use it in a production situation.
No support branches exist.

You can start a new support branch:

    git flux support start <name> <base>
_END

    is(
        exception { $flux->cmd('list') },
        $output,
        'initialized without support',
    );
}

{
    # list when support branches exist
    # should succeed

    my ( $flux, $repo ) = default_env();

    $flux->cmd( support => 'init', 'test_sup' );

    is(
        [ $flux->cmd( support => 'list' ) ],
        ['test_sup'],
        'support branch is listable',
    );
}

