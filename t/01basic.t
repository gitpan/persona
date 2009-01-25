BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# set up tests to do
use Test::More tests => 3 + ( 4 * 3 ) + 4 + 1;

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

print "all in Foo\\n";
#PERSONA one
print "one only\\n";
#PERSONA one two
print "one and two\\n";
#PERSONA !one
print "not one\\n";
#PERSONA
print "all in Foo again\\n";
1;
__END__
#PERSONA one
print "one should never show\\n";
#PERSONA
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
my $postfix = "-M$module -e1 2>&1 |";
my $all = <<"ALL";
all in Foo
one only
one and two
not one
all in Foo again
ALL

# no interference from persona whatsoever
foreach ( '', 'PERSONA=zero ', 'PERSONA=one ', 'PERSONA=two ' ) {
    my $prefix .= "$_$^X -I.";
    open( $out, "$prefix $postfix" );
    is( readline($out), $all, "$prefix no interference" );
    open( $out, "$prefix -Mpersona $postfix" );
    is( readline($out), $all, "$prefix no module selected, no interference" );
    open( $out, "$prefix -Mpersona=only_for,Bar $postfix" );
    is( readline($out), $all, "$prefix Bar module selected, no interference" );
}

# interference
my $prefix = "$^X -I.";
open( $out, "$prefix -Mpersona=only_for,Foo $postfix" );
is( readline($out), $all, 'Foo module selected, no PERSONA, no interference' );
open( $out, "PERSONA=zero $prefix -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA zero' );
all in Foo
not one
all in Foo again
OK
open( $out, "PERSONA=one $prefix -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA one' );
all in Foo
one only
one and two
all in Foo again
OK
open( $out, "PERSONA=two $prefix -Mpersona=only_for,Foo $postfix" );
is( readline($out), <<'OK', 'Foo module selected, PERSONA two' );
all in Foo
one and two
not one
all in Foo again
OK

# we're done
ok( unlink($filename), 'remove module' );
