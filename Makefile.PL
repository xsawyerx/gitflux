use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Git::Flux',
    AUTHOR              => q{Sawyer X <xsawyerx@cpan.org>},
    VERSION_FROM        => 'lib/Git/Flux.pm',
    ABSTRACT_FROM       => 'lib/Git/Flux.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-Flux-*' },
);
