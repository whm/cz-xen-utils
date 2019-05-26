# ------------------------------------------------------------------------
# Copyright 2012-2014 Board of Trustees, Leland Stanford Jr. University
# Copyright 2015-2018 Bill MacAllister <bill@ca-zephyr.org>
#
# This module is used by Xen support routines

package CZ::Xentools;

use Authen::Krb5;
use Carp;
use strict;

BEGIN {

    use Exporter();

    our @ISA    = qw(Exporter);
    our @EXPORT = qw(
      create_ticket_cache
      destroy_ticket_cache
    );

    our $VERSION = '1';

}

# ------------------------------------------------------------------------
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
    $cc->initialize($client)
      or die 'ERROR: '
      . 'Problem initializing Kerberos ticket cache, '
      . "KRB5CCNAME = $tgtEnv, "
      . 'krb_principal = '
      . $CONF->krb_principal
      . "tgt = $tgt";
    my $kt = Authen::Krb5::kt_resolve($CONF->krb_keytab);
    Authen::Krb5::get_in_tkt_with_keytab($client, $server, $kt, $cc)
      or die 'ERROR: '
      . Authen::Krb5::error()
      . " while getting Kerberos ticket";
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

END { }

1;

=head1 NAME

CZ::Xentools - Utility routines for the Xen support

=head1 SYNOPSIS

    use CZ::Xentools;

    create_ticket_cache();

=head1 DESCRIPTION

This module holds common routines and variables used by Xen
administration scripts.

=head1 FUNCTIONS

=over 4

=item B<create_ticket_cache>

Create a kerberos ticket cache.

=head1 AUTHOR

Bill MacAllister <bill@ca-zephyr.org>

=head1 COPYRIGHT

This software was originally developed for use at Stanford University
2012-2014.  All rights reserved.

Modifications to the software have been made by Bill MacAllister,
2015-2018.  All rights reserved.

=cut
