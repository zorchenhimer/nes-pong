#!/usr/bin/perl

use strict;
use warnings;

if ($#ARGV == -1) {
    print 'missing filename';
    exit 1;
}

my $inputfile = $ARGV[0];
$inputfile =~ /^(.+)\.([^\.]+)$/;
my $base = $1;

my @lines;

open(IN, '<', $inputfile)
    or die("Error opening input file: $!\n");

# FCEUX
open(OUT2, '>', "$base.nes.0.nl")
    or die("Error opening output file: $!\n");

# Mesen
open(OUT, '>', "$base.mlb")
    or die("Error opening output file: $!\n");

my $hexdiff = hex("0x8000");

my $found_res = 0;
my $count_labels = 0;
my $count_vars = 0;
my $count_locallabels = 0;

while( my $line = <IN> ) {
    next unless ($line =~ /^al /);
    chomp $line;

    my @row = split(/ /, $line);
    if ($#row != 2) {
        print "cannot parse line: $line\n";
        next;
    }
    my $label = substr $row[2], 1;
    my $addr = substr $row[1], 2;

    # FCEUX
    print OUT2 "\$$addr#$label#\n";

    # Mesen.  Mesen's labels are offsets from the start of code, not their absolute address.
    my $mesen_hex = "";
    if (hex($row[1]) < hex("0x8000")) {
        # Variables
        $mesen_hex = sprintf("R:%.4X:$label", hex("0x$row[1]"));
        $count_vars += 1;
    } else {
        # Labels
        $mesen_hex = sprintf("P:%.4X:$label", hex("0x$row[1]") - $hexdiff);

        if ($label =~ /^@/){
            # local labels
            $count_locallabels += 1;
        } else {
            # global labels
            $count_labels += 1;
        }
    }
    print OUT "$mesen_hex\n";
    #print "$mesen_hex\n";
}

close OUT;
close OUT2;
close IN;

print "  Labels: $count_labels\n  Local:  $count_locallabels\n  Vars:   $count_vars\n"
