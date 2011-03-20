package Git::Flux;

use Carp;
use Mouse;
use Try::Tiny;
use Git::Repository;
use Git::Flux::Response;

# commands 
with qw/
    Git::Flux::Utils
    Git::Flux::Command::init
    Git::Flux::Command::help
    Git::Flux::Command::feature
    Git::Flux::Command::hotfix
    Git::Flux::Command::release
/;

our $VERSION = '0.0_03';

# Class attributes
has dir => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has git_dir => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->run( 'rev-parse' => '--git-dir' );
    }
);

has repo => (
    is      => 'rw',
    isa     => 'Git::Repository',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Git::Repository->new( work_tree => $self->dir );
    }
);

has master_branch => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->run( config => qw/ --get gitflux.branch.master/ );
    }
);

has devel_branch => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->run( config => qw/ --get gitflux.branch.devel/ );
    }
);

has origin => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->run( config => qw/--get gitflux.origin/ ) || 'origin';
    }
);

sub run {
    my $self = shift;
    my ( $cmd, @opts ) = @_;

    # run help if no other cmd
    $cmd ||= $self->help();

    if ( !$self->meta->has_method($cmd) ) {
        return Git::Flux::Response->new(
            status => 0,
            error  => "`$cmd' is not supported"
        );
    }

    my $res;
    try {
        $res = Git::Flux::Response->new( message => $self->$cmd(@opts) );
    }
    catch {
        $res = Git::Flux::Response->new(
            status => 0,
            error  => $_,
        );
    };
    return $res;
}

1;

__END__

=head1 NAME

Git::Flux - A Perl port of gitflow

=head1 DESCRIPTION

We like gitflow and we like Perl and when we heard gitflow needs to be rewritten
in order to be more portable, we decided to get in gear.

C<gitflux> is the love child or Perl and gitflow.

=head1 SUBROUTINES/METHODS

=head2 new

Create a new object of Git::Flux.

=head3 dir

The directory which the Git::Flux instance will be working on.

You can also set this using the C<GITFLUX_DIR> environment variable.

=head3 repo

Internal L<Git::Repository> object that Git::Flux uses to do all the C<Git>
work.

You can construct your own and provide it on initialize.

=head2 run

Returns a L<Git::Flux::Response> object    

=head2 create_repo

A small helper function to create a repository. The directory is taken from
the C<dir> hash key in the object. If one does not exist (that means it was
not provided in C<new>), it uses the current directory.

=head1 AUTHORS

Sawyer X, C<< <xsawyerx at cpan.org> >>

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 BUGS

Please use the Github Issues tracker.

=head1 ACKNOWLEDGEMENTS

c<gitflow>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

