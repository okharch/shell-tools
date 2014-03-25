shell-tools
===========

scripts/aliases to work effectively within unix shell


==shenv.pl==

sources/imports specified scripts and also nested scripts and tries to figure out values of specified variables.
It DOES NOT execute specified scripts like bash would do.

So if we have

hello.sh:
export hello="hello world"

then 
shenv.pl hello.sh hello
will show
hello=hello world

It does not execute scripts - it uses regexes to "interpret" only those part of scripts which exports environment variables or sources other scripts.

It is quick and dirty way to find out specified environment variables value.
It works 90% for well formatted scripts, otherwise you always have long manual way to find out.

