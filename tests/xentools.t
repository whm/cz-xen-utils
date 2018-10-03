#!/usr/bin/perl -w
#
# tests/cz-xen.t

use Test::More qw( no_plan );

my $out;
my $s = '../usr/share/perl5/CZ/Xentools.pm';

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
    pass("$s is Tidy");
} else {
    fail("$s is UNTIDY");
}
unlink $t;

exit;


