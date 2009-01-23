BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# set up tests to do
use Test::More tests => 3 + 3 + 4 + 1;

# strict and verbose as possible
use strict;
use warnings;

# does it compile?
BEGIN { use_ok( 'persona' ) }

# set up source to check
my $module = 'Foo';
my $source = <<"SRC";
package $module;

use strict;
use warnings;

use persona;

print "all in Foo\\n";
print "one only\\n"    if !PERSONA or PERSONA eq 'one';
print "one and two\\n" if !PERSONA or PERSONA eq 'one' or PERSONA eq 'two';
print "not one\\n"     if !PERSONA or PERSONA ne 'one';
print "all in Foo again\\n";
__DATA__
print "one should never show\\n" if !PERSONA or PERSONA eq 'one';
print "all should never show\\n";
SRC

# make sure we have it as a file
my $filename = "$module.pm";
open( my $out, '>', $filename ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# ok string if there is no interference
my $postfix = "-e 'use $module' 2>&1 |";
my $all = <<"ALL";
all in Foo
one only
one and two
not one
all in Foo again
ALL

# no interference from persona whatsoever
open( $out, "$^X -I. $postfix" );
is( readline($out), $all, "no interference" );
open( $out, "$^X -I. -Mpersona $postfix" );
is( readline($out), $all, "no module selected, no interference" );
open( $out, "$^X -I. -Mpersona=only_for,Bar $postfix" );
is( readline($out), $all, "Bar module selected, no interference" );

# interference
open( $out, "$^X -I. -Mpersona=only_for,Foo $postfix" );
is( readline($out), $all, 'Foo module selected, no PERSONA, no interference' );
open( $out, "PERSONA=zero $^X -I. -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA zero' );
all in Foo
not one
all in Foo again
OK
open( $out, "PERSONA=one $^X -I. -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA one' );
all in Foo
one only
one and two
all in Foo again
OK
open( $out, "PERSONA=two $^X -I. -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA two' );
all in Foo
one and two
not one
all in Foo again
OK

# we're done
ok( unlink($filename), 'remove module' );
