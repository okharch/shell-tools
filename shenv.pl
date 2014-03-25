#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp qw(read_file);

my %env = %ENV;

my ($help) = grep m{^-h}, @ARGV;
if ($help || @ARGV==0) {
    print qq{Usage:
    $0 scripts vars
To source(import) variables from bash scripts and show their supposed values 
while these scripts will be executed.
It does not try to execute any commands - just 
recognizes lines for sourcing other scripts and lines for setting environment variables.
Then it keeps this values and expand values wherever it is needed/possible.
Then it shows supposed state of specified variables.
It can be useful to find out supposed value for some variable inside script.
It works 90% (I hope) but sometime it fails - then try to find out values other way
};
exit 1;
}


my @p = grep !m{^-}, @ARGV;
my @scripts = grep -f, @p;
warn "No scripts to source specified" unless @scripts;
my @vars = grep !-f, @p;
die "No vars specified to show" unless @vars;

my ($verbose) = grep m{^-v}, @ARGV;

import_script($_) for @scripts;

for my $var (@vars) {
    my $val = exists $env{$var}?"=".$env{$var}:": this was not found";
    print "$var$val\n";
}
exit 0;

sub env_var {
    local $_ = substr($_[0],1); # remove dollar sign
    s/[{}]//g; # remove {}
    return $_;
}

sub expand_vars($) {
    local $_ = shift;
    my @vars = m/(\${.*})/g;
    push @vars, m/(\$[A-Za-z0-9_]+)/g;
    s/\~/$ENV{HOME}/g;
    if (@vars) {
        my %v;
        $v{$_} = env_var($_) for @vars;
        for my $var (keys %v) {
            next unless exists $env{$v{$var}};
            my $val = $env{$v{$var}};
            my $find = "\\".$var;
            s/$find/$val/g;
        }
    }
    return $_;
}

# store all export lines to %env
sub import_lines(\@) {
    my ($lines) = @_;
}

my %imported;
sub import_script {
    my $file = expand_vars($_[0]);
    unless (-f $file) {
        warn "file $file was not found: $_[0]" if $verbose;
        return;
    }
    return if $imported{$file}++;
    my @lines = read_file($file);
    for (@lines) {
        my ($var,$val) = m{export\s+(\S+?)\s*=\s*(.*)};
        ($var,$val) = m{setenv\s+(\S+?)\s+(.*)} unless $var;
        if ($var) {
            $val = expand_vars($val);
            $env{$var} = $val if $var;
            next;
        }
        my ($file) = map {-f $_?$_:`which $_ 2>/dev/null`} m{^(?:\.|source)\s+(\S+)};
        if ($file) {
            chomp $file;
            import_script($file) if -f $file;
            next;
        }
    }
}
