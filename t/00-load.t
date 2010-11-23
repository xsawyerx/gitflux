use strict;
use warnings;
use Test::More;
use File::Find;
use Git::Repository;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, 'blib/lib' );

plan tests => scalar @modules;

use_ok($_)
    for reverse sort map { s!/!::!g; s/\.pm$//; s/^blib::lib:://; $_ }
    @modules;

diag( "Testing Git::Flux $Git::Flux::VERSION, Perl $], $^X" );
diag( "Testing with Git::Repository $Git::Repository::VERSION" );

if ( Git::Repository::Command::_is_git('git') ) {
    diag( "Testing with Git " . Git::Repository->version );
} else {
    diag("Testing without Git installed");
}

