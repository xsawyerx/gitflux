use strict;
use warnings;

use File::Temp 'tempdir';
use Cwd 'cwd';
use Git::Repository;

sub create_empty_repo {
    my $dir = tempdir( CLEANUP => 1 );
    my $orig = cwd();
    chdir $dir or die "Can't chdir back to $dir: $!";
    my $repo = Git::Repository->create('init');
    chdir $orig or die "Can't chdir back to $orig: $!";
    return $repo;
}

1;
