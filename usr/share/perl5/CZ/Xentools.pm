# ------------------------------------------------------------------------
# Copyright 2012-2014 Board of Trustees, Leland Stanford Jr. University
# Copyright 2015-2019 Bill MacAllister <bill@ca-zephyr.org>
#
# This module is used by Xen support routines

package CZ::Xentools;

use Authen::Krb5;
use Carp;
use File::Basename;
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
    );

    our $VERSION = '1';

}

my $DEBUG;

# ----------------------------------------------------------------------
# Initialize CA tools

sub cz_init_tools {
    my ($id, $debug) = @_;
    if (!$id) {
        $id = basename($0);
    }
    if ($debug) {
        $DEBUG = 1;
        msg("DEBUG: Starting debugging output\n");
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

END { }

1;

=head1 NAME

CZ::Xentools - Utility routines for the Xen support

=head1 SYNOPSIS

    use CZ::Xentools;

    create_ticket_cache();
    destroy_ticket_cache();
    cz_init_tools(<script>, <debug flag>);
    cz_syslog(<text>, <syslog level>);
    msg(<text>);

=head1 DESCRIPTION

This module holds common routines and variables used by Xen
administration scripts.

=head1 FUNCTIONS

=over 4

=item B<create_ticket_cache>

Create a kerberos ticket cache.

=item B<destroy_ticket_cache>

Destroy a kerberos ticket cache.

=item B<cz_init_tools(<script name>, <debug flag>)

Both parameters are optional.  This routine initializes the syslog
interface and controls debugging output from CZ::Xentools routines.

=item B<cz_syslog(<text>, <syslog level>)

Send text to syslog.  The syslog level is optional and if not set 
the level is NOTICE.

=item B<msg(<text>)

Send text to STDOUT trapping any errors.

=head1 AUTHOR

Bill MacAllister <bill@ca-zephyr.org>

=head1 COPYRIGHT

This software was originally developed for use at Stanford University
2012-2014.  All rights reserved.

Modifications to the software have been made by Bill MacAllister,
2015-2019.  All rights reserved.

=cut
