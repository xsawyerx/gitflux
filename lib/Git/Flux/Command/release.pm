package Git::Flux::Command::release;

use Mouse::Role;
use Git::Flux::Response;

sub release {
    my $self = shift;
    my $cmd  = shift || 'list';

    my $method = "release_$cmd";
    $self->gitflux_load_settings();

    $self->$method(@_);
}

sub release_list {
    my $self = shift;

    my $repo = $self->repo;
    my $prefix = $self->feature_prefix();

    my @releases_branches = grep { /^$prefix/ } $self->git_local_branches();

    if ( !scalar @features_branches ) {
        my $error = qq{
No release branches exist.

You can start a new release branch:

    gitflux release start <name> [<base>]

};
        return Git::Flux::Response->new(
            status => 0,
            error  => $error
        );
    }

    
}

1;
