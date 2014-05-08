#!/usr/bin/env perl 
# this can be run as cygwin service (using screen) to avoid proxifying for 14.2.66.50
# if you can't assign proxy options for browser. use http://localhost:3000 instead 14.2.66.50:3000
use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::Server::Daemon;
use Data::Dumper;

my ($listen,$forward_host,$forward_port) = @ARGV;

die "please specify protocol and port to listen at localhost (e.g. 'http://*:3000')" unless $listen;
my ($scheme) = $listen =~ m{^(.*?):};
die "invalid scheme to forward : $scheme, please use http or https" unless $scheme =~ m{^https?$};

die "please specify host to forward requests e.g. '14.2.66.50'" unless $forward_host;
die "please specify port at forwarded host" unless $forward_port;


my $ua = Mojo::UserAgent->new;
$ua->proxy->not([$forward_host]);

my $daemon = Mojo::Server::Daemon->new(
  listen => [$listen]
)->unsubscribe('request');
$daemon->on(request => sub {
  my ($daemon, $tx) = @_;

  my $req = $tx->req->clone;
  my $scheme = $req->url->scheme($scheme);
  $scheme->host($forward_host);
  $scheme->port($forward_port);
  #print "=== REQUEST ===\n";  print Dumper($req);
  
  $ua->start(Mojo::Transaction::HTTP->new(req => $req) => sub {
    my ($ua, $proxy_tx) = @_;
    #print Dumper($proxy_tx);
    $tx->res($proxy_tx->res)->resume;
  });
});

$daemon->run;
