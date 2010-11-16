#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Temp 'tempdir';
use Test::More skip_all => 'feature not implemented yet'; # 1
use TestFunctions;

my ( $flux, $repo ) = default_env();
my @data = $flux->run( feature => 'help' );

like(
    $data[0],
    qr/^ usage\: \s git \s flux \s \[list\] \s \[-f\]/,
    'help works, got usage line'
);

