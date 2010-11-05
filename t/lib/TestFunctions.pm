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

sub configure_default_repo {
    my $repo = shift;

    # got master, develop configured
    $repo->cmd( config => 'gitflux.branch.master',  'master'  );
    $repo->cmd( config => 'gitflux.branch.develop', 'develop' );

    # has prefixes configured for every branch
    # (feature, release, hotfix, support)
    foreach my $prefix ( qw/ feature release hotfix support / ) {
        $repo->cmd( config => "gitflux.prefix.$prefix", "$prefix/" );
    }

    # versiontag configured
    $repo->cmd( config => 'gitflux.prefix.versiontag', 'v' );
}

1;
