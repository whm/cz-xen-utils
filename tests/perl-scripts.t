#!/usr/bin/perl -w
#
# tests/cz-xen.t

use Test::More qw( no_plan );

my @script_list = (
    'cz-xen',
    'cz-xen-backup',
    'cz-xen-backup-control',
    'cz-console',
);

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

    my $t = "${s}.tdy";
    my @cmd = ('perltidy');
    push @cmd, '-bbao';  # put line breaks before any operator
    push @cmd, '-nbbc';  # don't force blank lines before comments
    push @cmd, '-ce';    # cuddle braces around else
    push @cmd, '-l=79';  # don't want 79-long lines reformatted
    push @cmd, '-pt=2';  # don't add extra whitespace around parentheses
    push @cmd, '-sbt=2'; # ...or square brackets
    push @cmd, '-sfs';   # no space before semicolon in for
    push @cmd, $s;
    system(@cmd);

    @cmd = ('diff', '-u', $s, $t);
    if (system(@cmd) == 0) {
        pass("$script is Tidy");
    } else {
        fail("$script is UNTIDY");
    }
    unlink $t;
}

exit;


