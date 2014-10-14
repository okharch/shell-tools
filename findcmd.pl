#!/usr/bin/env perl

use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Storable qw(nstore retrieve);

my $cmd_info_fn = "$ENV{HOME}/etc/cmd_info";

my $force_rebuild = 1; # rebuild each time and don't store cache
my ($re) = grep m{^[^-]},@ARGV;

my ($rebuild) = $force_rebuild || grep m{^-r}, @ARGV;

my $cmd_info = $rebuild? rebuild_cmd_info() : retrieve $cmd_info_fn; # if $rebuild || !-e $cmd_info_fn;

die "please specify any sample to find" unless defined($re);

$\ = $, = "\n";

for my $cmd_class (qw(alias function bin)) {
    my @cmd_name = sort keys(%{$cmd_info->{$cmd_class}});
    print "$cmd_class: $_" for grep m{$re}, @cmd_name;
    for my $cmd_name (@cmd_name) {
        my $lines = $cmd_info->{$cmd_class}{$cmd_name};
        print "$cmd_class: $cmd_name: $_" for grep m{$re}, @$lines;
    }
}

sub fq {
    "$_";
}

sub rebuild_cmd_info {
    my %cmd_info = (
        'function' => build_function(),
        'alias' => build_alias(),
        'bin' => build_bin(),
    );
    nstore \%cmd_info, $cmd_info_fn unless $force_rebuild;
    return \%cmd_info;
}

sub build_function {
    my @functions = `/bin/bash --login -c "typeset -f"`;
    my %functions;
    my ($function,@lines);
    for (@functions) {
        chomp;
        if (m{^(\S+) \(\)}) { # this starts new function definition
            $functions{$function} = \@lines if $function;
            @lines = ();
            $function = $1;
            next;
        }
        s/^\s+//;
        push @lines,$_  unless m{^[{}]$}; # don't put to lines "{" and "}"
    }
    $functions{$function} = \@lines if $function;
    return \%functions;
}

sub build_alias {
    return {map { m{^alias (.*?)=(.*?)\s*$} ? ($1 => [$2]) : () } `/bin/bash --login -c "alias"`};
}

sub build_bin {
    my $PATH = join " ",map fq,split /:/, $ENV{PATH}; 
    my @bin = `ls $PATH`;
    chomp @bin;
    # we could read script content here as a lines, but don't do it to reduce search hits
    return {map {$_ => []} @bin};
}
