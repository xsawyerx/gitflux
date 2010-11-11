#!perl

use strict;
use warnings;

use lib 't/lib/';
use Git::Flux;

use File::Temp 'tempdir';
use Test::More tests => 1;
use TestFunctions;

my $repo = create_empty_repo();
my $flux = Git::Flux->new( dir => $repo->work_tree );
my @data = $flux->cmd( feature => 'help' );

like(
    $data[0],
    qr/^ usage\: \s git \s flux \s \[list\] \s \[-f\]/,
    'help works, got usage line'
);
