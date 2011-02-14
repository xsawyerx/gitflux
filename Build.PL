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
        'Test::More'       => 0,
        'File::Temp'       => 0,
        'File::Slurp'      => 0,
        'Test::Fatal'      => 0,
        'Test::TinyMocker' => 0,
    },

    requires => {
        'perl'            => 5.006,
        'Git::Repository' => 0,
        'mixin'           => 0,
        'Try::Tiny'       => 0,
        'Term::ReadLine'  => 0,
        'List::MoreUtils' => 0,
    },

    add_to_cleanup       => [ 'Git-Flux-*' ],
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    create_license       => 1,
    recursive_test_files => 1,

    meta_merge => {
        repository  => 'http://github.com/xsawyerx/gitflux/'
    },
);

$builder->create_build_script();
