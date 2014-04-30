#!/bin/env perl
use strict;
use warnings;
use File::Spec;
use File::Slurp;
use Plucene::Index::Writer;
use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Document;
use Plucene::Document::Field;
use Plucene::QueryParser;
use Plucene::Search::IndexSearcher;

$|=1;
check_and_search(@ARGV);
exit 0;

sub check_and_search {
    my ($directory,@search) = @_;
    die "Use $0 directory search" unless $directory && -d $directory;
    my $reindex = @search && ($search[0] eq '-reindex');
    shift @search if $reindex;
    $directory = File::Spec->rel2abs($directory);
    my $index_path = dir_indexpath($directory);
    my $index_exists = -e $index_path;
    create_index($directory,$index_path) if $reindex || !$index_exists;
    if (@search) {
        my $searcher = Plucene::Search::IndexSearcher->new($index_path);
        my @files = map $directory."/".$_->[0]->get('file')->get('string'), search_index($searcher,@search);
        for my $file (@files) {
            print "$file\n";
        }
    } else {
        die "Use $0 directory -reindex\nto force reindex" unless $reindex;
    }
}

# create index at "$index_path.indexing", then rename directory to $index_path. 
# this is to make it possible to work with an old index while new index is being created
sub create_index {
    my ($directory,$index_path) = @_;
	my $analyzer = Plucene::Analysis::SimpleAnalyzer->new();
    my $indexing_path = "$index_path.indexing";
    die "already indexing : $indexing_path" if -e $indexing_path;
	my $writer = Plucene::Index::Writer->new($indexing_path, $analyzer, 1);
	print "creating index $index_path...\n";
	open my $files,'-|',"find $directory|xargs file" || die "can't open files pipe: $!";
	my ($count,$size) = (0,0);
	my $started = time;
	while (<$files>) {
		my ($file) = m{^(.*?):\s+.* text};
		next unless $file;
		$count++;
		my $doc = Plucene::Document->new;
		my $content = read_file($file);
		$size += length($content);
		printf "indexing files %d, bytes %s\r",$count,commify($size) unless $count % 10;
        $doc->add(Plucene::Document::Field->Text(content => $content));
		$file =~ s{^$directory/}{};        
        $doc->add(Plucene::Document::Field->Text(file => $file));
		$writer->add_document($doc);
	}
	printf "indexed files %d, bytes %d in %d seconds, optimizing...",$count,$size,time-$started;
	my $ostarted = time;
	$writer->optimize;
    undef $writer; # close index
    # remove an old index
    while (-e $index_path && system("rm -rf $index_path")) {
        print "was not able to remove old index, press enter to try again...";
        <>;
    }
    system("mv $indexing_path $index_path");
	printf "done in %d second\n",time-$ostarted;
}


# 1234567890 => 1,234,567,890
sub commify {
	local $_  = shift;
	1 while s/^(-?\d+)(\d{3})/$1,$2/;
	return $_;
}


sub dir_indexpath {
    my $h = $ENV{HOME};
    my $IDIR = "$h/.plucene";
    mkdir $IDIR unless $IDIR;
    local $_ = shift;
    s{^$h/}{};
    s{/}{-}g;
    return "$IDIR/$_";
}

sub search_index {
    my ($searcher,@search) = @_;
	my $parser = Plucene::QueryParser->new({
			analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
			default  => "content" # Default field for non-specified queries
	});
	my $query = $parser->parse(join ' ',@search);
	my @docs;
	my $hc = Plucene::Search::HitCollector->new(collect => sub {
			my ($self, $doc, $score) = @_;
			push @docs, [$searcher->doc($doc),$score];
	});

	$searcher->search_hc($query => $hc);
	
	return sort {$b->[1] <=> $a->[1]} @docs;
}


