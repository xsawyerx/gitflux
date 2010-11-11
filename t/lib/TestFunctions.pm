use strict;
use warnings;

use File::Temp 'tempdir';
use Cwd 'cwd';
use Git::Repository;

sub default_env {
    my $repo = create_empty_repo();
    my $flux = Git::Flux->new( dir => $repo->work_tree );
    configure_default_repo($repo);

    return $flux, $repo;
}

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
    $repo->run( config => 'gitflux.branch.master',  'master'  );
    $repo->run( config => 'gitflux.branch.develop', 'develop' );

    # has prefixes configured for every branch
    # (feature, release, hotfix, support)
    foreach my $prefix ( qw/ feature release hotfix support / ) {
        $repo->run( config => "gitflux.prefix.$prefix", "$prefix/" );
    }

    # versiontag configured
    $repo->run( config => 'gitflux.prefix.versiontag', 'v' );
}

1;
