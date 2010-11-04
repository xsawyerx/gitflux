#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Git::Flux' ) || print "Bail out!\n";
}

diag( "Testing Git::Flux $Git::Flux::VERSION, Perl $], $^X" );
