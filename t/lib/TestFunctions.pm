use strict;
use warnings;

use File::Temp 'tempdir';
use Git::Repository;

sub create_empty_repo {
    my $dir  = tempdir( CLEANUP => 1 ); 
    my $repo = Git::Repository->create( init => $dir );
    return $repo;
}

1;
