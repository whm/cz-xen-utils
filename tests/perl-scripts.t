#!/usr/bin/perl -w
#
# tests/cz-xen.t

use Test::More qw( no_plan );

my @script_list = ('cz-xen', 'cz-xen-backup', 'cz-console');

for my $script (@script_list) {

    my $out = '';
    my $s = "../usr/bin/$script";
    my $cmd = "PERLLIB=../usr/share/perl5 $s";

    $out = `$cmd --help 2>&1`;
    if (!ok($out =~ /^Usage/, "$script Help Switch")) {
        `$cmd --help`;
    }

    $out = `$cmd help 2>&1`;
    if (!ok($out =~ /^Usage/, "$script Help")) {
        `$cmd --help`;
    }

}

exit;
