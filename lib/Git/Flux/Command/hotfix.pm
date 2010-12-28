package Git::Flux::Command::hotfix;

use strict;
use warnings;
use mixin::with 'Git::Flux';

# TODO
# list (-v): need tests
# start (-F version base):
# finish (-Fsumpk version):

sub hotfix {
    my $self = shift;
    my $cmd = shift || 'list';
    my $method = "hotfix_$cmd";

    $self->gitflux_load_settings();

    $self->$method(@_);
}

sub hotfix_list {
    my $self = shift;
    my $verbose = shift || 0;

    my @hotfix_branches = grep { /^$prefix/ } $self->git_local_branches();

    if (scalar @hotfix_branches == 0) {
        print << "__END_REPORT";
No hotfix branches exists

You can start a new hotfix branch:

    git flow hotfix start <name> [<base>]

__END_REPORT
        return;
    }

    my $current_branch = $self->git_current_branch();
    my $master_branch   = $self->{'master_branch'};
    my $repo = $self->{repo};

    foreach my $branch (@hotfix_branches) {
        my $base = $repo->run( 'merge-base' => $branch => $master_branch );
        my $master_sha = $repo->run('rev-parse' => $master_branch);
        my $branch_sha = $repo->run('rev-parse' => $branch);
        if ($branch eq $current_branch) {
            print '* ';
        }else{
            print ' ';
        }
        print "$branch\n";
    }
}

sub hotfix_start {
    my $self = shift;


}

1;
