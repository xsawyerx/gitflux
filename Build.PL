use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Git::Flux',
    license             => 'perl',
    dist_author         => q{Sawyer X <xsawyerx@cpan.org>},
    dist_version_from   => 'lib/Git/Flux.pm',
    build_requires => {
        'Test::More' => 0,
    },

    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Git-Flux-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
