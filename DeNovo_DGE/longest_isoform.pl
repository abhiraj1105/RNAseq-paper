#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "Usage: $0 input.fasta > longest_isoforms.fasta\n";
my $file = shift or die $usage;

open(my $fh, "<", $file) or die "Cannot open $file: $!";

my (%seqs, %headers);

my ($header, $seq) = ("", "");

while (<$fh>) {
    chomp;
    if (/^>/) {
        process_record($header, $seq) if $header;
        $header = $_;
        $seq = "";
    }
    else {
        $seq .= $_;
    }
}
process_record($header, $seq) if $header;

close $fh;

foreach my $gene (sort keys %seqs) {
    print $headers{$gene}, "\n";
    print $seqs{$gene}, "\n";
}

sub process_record {
    my ($header, $seq) = @_;

    # Get first token after ">"
    my ($id) = $header =~ /^>(\S+)/;

    # Remove .p1, .p2, etc.
    $id =~ s/\.p\d+$//;

    # Extract Trinity gene ID
    my ($gene) = $id =~ /^(TRINITY_DN\d+_c\d+_g\d+)/;

    unless ($gene) {
        warn "Skipping unrecognized ID: $id\n";
        return;
    }

    if (!exists $seqs{$gene} || length($seq) > length($seqs{$gene})) {
        $seqs{$gene} = $seq;
        $headers{$gene} = $header;
    }
}
