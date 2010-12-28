use strict;
use warnings;

use Test::More;
use Git::Repository;

plan tests => 5;

use_ok "Git::Flux::Utils";
use_ok "Git::Flux::Command::help";
use_ok "Git::Flux::Command::init";
use_ok "Git::Flux::Command::feature";
use_ok "Git::Flux::Command::hotfix";

diag( "Testing Git::Flux $Git::Flux::VERSION, Perl $], $^X" );
diag( "Testing with Git::Repository $Git::Repository::VERSION" );

if ( Git::Repository::Command::_is_git('git') ) {
    diag( "Testing with Git " . Git::Repository->version );
} else {
    diag("Testing without Git installed");
}

