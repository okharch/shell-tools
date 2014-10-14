#!/usr/bin/env perl

use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Storable qw(nstore retrieve);
use Getopt::Long;
use Pod::Usage;
use Text::Soundex;

my $man = 0;    
my $help = 0;
my $cache;
my $soundex;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?' => \$help, man => \$man, 'cache=s' => \$cache, soundex => \$soundex);

my ($re) = @ARGV;

my $cmd_info;
$cmd_info =  $cache && -e $cache? retrieve($cache) : rebuild_cmd_info();
nstore $cmd_info, $cache if $cache && !-e $cache;

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: please specify any sample to find") unless defined($re);

$\ = $, = "\n";
if ($soundex) {
    my $arg_soundex = soundex($re);
    print $_ for @{$cmd_info->{soundex}{$arg_soundex}||[]};
    exit 0;
}

$cmd_info = $cmd_info->{plain};

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
    my %plain = (
        'function' => build_function(),
        'alias' => build_alias(),
        'bin' => build_bin(),
    );
    my @cmd = grep defined($_->[1]), 
    map [$_,soundex($_)], map keys(%{$plain{$_}}),qw(function alias bin);
    my %soundex;
    push @{$soundex{$_->[1]}},$_->[0] for @cmd;
    return {soundex => \%soundex, plain => \%plain};
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

__END__

=head1 NAME

findcmd.pl - build list of all bash functions, aliases, bin files from PATH and search over this names with specified regexp

=head1 SYNOPSIS

findcmd.pl [options] PATTERN

finds regexp PATTERN over list of bash commands and their definitions (for aliases and functions)

 Options:
   -help            brief help message
   -man             full documentation
   -soundex         use soundex algorithm to match the pattern over command names
   -cache=file      force to use cache in a case you have huge collection of commands and it's building on the fly takes long time.

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-cache=file>

It will build the cached list of bash commands and their definition.
When cache is available it is loaded instantly and search over it.
Use this options if builing of the list for search takes a long time.
Usually it does not.

=item B<-soundex>

Use soundex algorithm to match the pattern over command names

=back

=head1 DESCRIPTION

B<findcmd.pl> builds the list of all commands (aliases, functions, binary over PATH) that is defined in ~./profile (see bash login invocation).
Take into account that commands defined at .bashrc (interactive invokation) are not available to search over.
It is good if you remember there was some command that sounds like this, but do not remember it's exact spelling

=cut
