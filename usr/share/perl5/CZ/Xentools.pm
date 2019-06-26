# ------------------------------------------------------------------------
# Copyright 2012-2014 Board of Trustees, Leland Stanford Jr. University
# Copyright 2015-2019 Bill MacAllister <bill@ca-zephyr.org>
#
# This module is used by Xen support routines

package CZ::Xentools;

use Authen::Krb5;
use Carp;
use File::Basename;
use IPC::Run qw( start pump finish timeout );
use strict;
use Sys::Syslog;

BEGIN {

    use Exporter();

    our @ISA    = qw(Exporter);
    our @EXPORT = qw(
      create_ticket_cache
      cz_syslog
      cz_init_tools
      destroy_ticket_cache
      msg
      run_cmd_tty
    );

    our $VERSION = '1';

}

# ----------------------------------------------------------------------
# Initialize CA tools

sub cz_init_tools {
    my ($id) = @_;
    if (!$id) {
        $id = basename($0);
    }
    openlog($id, 'pid', 'local3');
    return;
}

# ----------------------------------------------------------------------
# Write a syslog message

sub cz_syslog {
    my ($msg, $level) = @_;
    if (!$level) {
        $level = 'NOTICE';
    }
    syslog($level, $msg);
    return;
}

# ----------------------------------------------------------------------
# Create kerberos ticket cache

sub create_ticket_cache {
    my ($CONF) = @_;

    if ($CONF->krb_principal eq 'none') {
        die("ERROR: missing krb_principal\n");
    }

    # Use existing tgt_file it one exists
    my $tgtEnv = 'FILE:' . $CONF->tgt_file;
    if (-e $CONF->tgt_file) {
        $ENV{KRB5CCNAME} = $tgtEnv;
        return;
    }

    my $tgt = 'krbtgt/' . $CONF->krb_realm;
    Authen::Krb5::init_context();
    Authen::Krb5::init_ets();
    my $client = Authen::Krb5::parse_name($CONF->krb_principal);
    my $server = Authen::Krb5::parse_name($tgt);
    my $cc     = Authen::Krb5::cc_resolve($tgtEnv);

    my $info = "INFO: KRB5CCNAME = $tgtEnv\n";
    $info .= 'INFO: krb_principal = ' . $CONF->krb_principal . "\n";
    $info .= "INFO: tgt = $tgt\n";

    $cc->initialize($client)
      or die "ERROR: Problem initializing Kerberos ticket cache\n" . $info;
    my $kt = Authen::Krb5::kt_resolve($CONF->krb_keytab);
    Authen::Krb5::get_in_tkt_with_keytab($client, $server, $kt, $cc)
      or die 'ERROR: '
      . Authen::Krb5::error()
      . " while getting Kerberos ticket\n"
      . $info;
    $ENV{KRB5CCNAME} = $tgtEnv;
    return;
}

# ------------------------------------------------------------------------
# Destroy kerberos ticket cache

sub destroy_ticket_cache {
    my ($CONF) = @_;
    if (-e $CONF->tgt_file) {
        unlink $CONF->tgt_file;
    }
    return;
}

# ----------------------------------------------------------------------
# output information

sub msg {
    (my $tmp) = @_;
    print {*STDOUT} $tmp
      or croak("Problem writing to STDOUT\n");
    return;
}

# ----------------------------------------------------------------------
# Run a command using a pseudo terminal.  Using a terminal allows
# for progress displays to be returned as the command executes.
# Default timeout is 10 minutes;

sub run_cmd_tty {
    my ($cmd, $timeout) = @_;

    if (!$timeout) {
        $timeout = 600;
    }

    # Initialize shell session
    my @bash = qw( bash );
    my $handle;
    my $in;
    my $out;
    my $err;
    $handle = start \@bash, '<pty<', \$in, '>pty>', \$out, \$err,
      timeout($timeout);

    # Send the command and print any output
    $in .= "$cmd ; echo ''; echo 'ENDOFCOMMAND'\n";
    until ($out =~ /ENDOFCOMMAND\n/g) {
        pump $handle;
        my $display = $out;
        my @lines = split /\n/, $display;
        for my $l (@lines) {
            if ($l =~ /^\s*\d/xms) {
                msg($l);
            }
        }
    }

    # Close bash session
    my $info_msg = "INFO: command = $cmd";
    finish $handle or die "$info_msg\nERROR: bash returned $?";
    if ($err) {
        msg("$info_msg\n");
        msg("ERROR: command returned $err\n");
    }
    return;
}

END { }

1;

=head1 NAME

CZ::Xentools - Utility routines for the Xen support

=head1 SYNOPSIS

    use CZ::Xentools;

    create_ticket_cache();
    destroy_ticket_cache();
    run_cmd_tty(<command>, <timeout>);

=head1 DESCRIPTION

This module holds common routines and variables used by Xen
administration scripts.

=head1 FUNCTIONS

=over 4

=item B<create_ticket_cache>

Create a kerberos ticket cache.

=item B<destroy_ticket_cache>

Destroy a kerberos ticket cache.

=item B<run_cmd_tty(command, timeout)>

Run a command in a pseudo terminal and display output as the
command executes.

=head1 AUTHOR

Bill MacAllister <bill@ca-zephyr.org>

=head1 COPYRIGHT

This software was originally developed for use at Stanford University
2012-2014.  All rights reserved.

Modifications to the software have been made by Bill MacAllister,
2015-2019.  All rights reserved.

=cut
