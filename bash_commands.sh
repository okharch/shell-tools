# usefull shell aliases and functions 

# I like when (shell) cd make guesses where do I want to go
export CDPATH=.:..:../..:~:~/tmp

# this is alias to get N-th word from argument
alias fw=gw

# plucedir.pl is for creating indexes on directories and searching through it
alias sd=plucedir.pl

# this function splits list of pathes separated by : make them unique and join them b y ":"
function upath {
perl -nle'print join "\n",split /:/'|uniq|paste -s -d":"
}

# grep over (zipped) files and output found lines to stdout and clipboard
function zcgrep {
zegrep $* | tee ~/tmp/cgrep
sendclip ~/tmp/cgrep
}

# read stdin, extract N-th word from it and output it
function gw {
perl -lne'@w=m{(\S+)}g;print $w[$ARGV[0]||0]'
}

# read stdin output it and also duplicate output to clipboard
function osc {
tee ~/tmp/out
sendclip ~/tmp/out
}

# list only directories
function lsd {
ls $*|perl -lne'print if -d'
}

# convert input parameters to datetime string and output them one per line
function utc {
perl -MDate::Format=time2str -e'print time2str("%Y-%m-%d %H:%M:%S",$_),"\n" for @ARGV' $*
}

# output access, modify, create time for specified file
function ftime {
perl -MDate::Format=time2str -e'print join("\t", $_, map time2str("%Y-%m-%d %H:%M:%S",$_), (stat($_))[8,9,10]),"\n" for @ARGV' $*
}

# input of md5sum or sha1sum to list of uniq by sum files
function sum_to_uniq_files {
perl -ne'($s,$f)=m{(\S+)}g;print "$f\n" unless $s{$s}++' $*
}

# output full name of specified file
function fn {
perl -MFile::Spec -e'print File::Spec->rel2abs(File::Spec->abs2rel(File::Spec->rel2abs($_))),"\n" for @ARGV' $*
}

# use this largs instead of xargs if you have space in filenames
alias largs="xargs -d '"\\n"'"

# this clear inserts 6 empty lines to mitigate "clean screen" op
alias cls='clear;for x in 1 2 3 4 5 6 ;do echo ""; done;'

# filter list of files to avoid files with the same filename ignoring full path
function uniqname {
perl -n -e'($n)=m{.*/(.*?)\s*$};print unless $u{$n}++'
}

# filterlist of files, calculate md5sum avoid to output file with equal md5sum
function uniqmd5 {
xargs md5sum|perl -ne'($s,$f)=m{(\S+)}g;print "$f\n" unless $s{$s}++'
}

# grep history
alias gh='history|egrep'

# grep through list of files
function gl { # cat file | xargs -d '\n' egrep $2 $3 $4 
if [ $# -ne 0 ]
then 
file=$1
shift
cat $file | xargs -d '\n' egrep $*
else
echo Use GrepList filelist searchstr
fi
}

# create zipped list of files in home directory and grep over that list
function mypath {
if [ $# -ne 0 ]
then
zegrep $1 ~/fl/mypath.gz|perl -lne'print if -e'|osc
else
# index mypath
mkdir -p ~/fl
(cd ~/fl;find ~ -name .snapshot -prune -o  -print|gzip - >mypath-tmp.gz;mv mypath-tmp.gz mypath.gz) &
echo mypath is being indexed
fi
}

# jump to ~/bin
alias b='cd ~/bin'

# mkdir and jump to it
function mkcd {
mkdir -p $1
cd $1
}

# output disk usage for specified directory with max-depth 1 and sort by disk usage
function du {
/usr/bin/du --max-depth 1 -h $*|perl -e'@r=<>;chomp for @r;print "$_\n" for sort {sz($a)<=>sz($b)} @r;sub sz{($n,$m)=$_[0]=~m{^([0-9.]+)([KMGT])?};$m=$m?(index("KMGT",$m)+1)*3:0;$n*10**$m}'
}

# trying to use curl without checking certificates
alias curl='curl -k'

# send linux input to clipboard at specified windows  host (need hardcoded tune of hostname)
alias sendclip='sendclip.pl -h windows-gui-host'

#perldb alias is perl tuned to execute DBI jobs
alias perldb='env PERL5LIB=/home/kharcheo/perl5/lib/perl5:/home/kharcheo/UbsTask/perllib:/home/kharcheo/UbsTask/CPAN/lib:/sbcimp/run/pd/csm/64-bit/cpan/5.16.3-2013.03/lib:/sbcimp/run/pd/csm/64-bit/cpan/5.16.3-2013.03/lib/x86_64-linux-thread-multi /sbcimp/run/pd/csm/64-bit/perl/5.16.3/bin/perl -w'

# dbiproxy executes proxy at linux/cygwin host in a case you have troubles with prper DBI setup for specific DBD driver
alias dbiproxy='screen -dm perldb /usr/bin/dbiproxy --configfile /home/kharcheo/dbi-proxy.conf'

# this alias could be used to count files in each directories: find /|count_match '(.*)/'
alias count_match="perl -MRegexp::Common -e'"'$m = shift;while(<>){$c{$_}++ for m{$m}g} print "$_\t$c{$_}\n" for sort {$c{$a} <=> $c{$b}} keys %c'"'"

# next pair of commands is used to build list of all accessible files starting from root and grepping through it. allows mitigate find /|grep sample much faster. usefull when you use find / often
function  allpath {
zegrep "$1" ~/fl/allpath.gz
}
function allpath_build {
(pushd ~/fl ; find / -name .snapshot -prune -o  -print| gzip - > allpath-tmp.gz ; mv allpath-tmp.gz allpath.gz; popd; echo "Updating allpath completed")
}

# shows $VERSION of perl module 
function pmv {
perl -M$1 -e'print eval(q{$}.$ARGV[0].q{::VERSION})."\n"' $1
}

# shows full path of perl module and it's $VERSION
function pm {
perl -e'$_=$m=$ARGV[0];s{::}{/}g;$_.=".pm" unless m{\.pm$};$pm=$_;for $f (grep -f,map "$_/$pm", grep !$u{$_}++, @INC) {do $f;print $f."\t".eval(q{$}.$m."::VERSION")."\n"}' $1
}

# find perl module and check it's syntax
function pmc {
perl -c `pm $1`
}

# edit ~/.bashrc and apply it immediately to current shell
function vibrc {
vi ~/.bashrc
. ~/.bashrc
}

which()
{
(alias;declare -f)|/usr/bin/which --read-functions --read-alias $*
}
