BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# set up tests to do
use Test::More tests => 2 + 4 + 1;

# strict and verbose as possible
use strict;
use warnings;

# set up source to check
my $source = <<"SRC";
use strict;
use warnings;

use persona;

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
my $filename = "foo";
open( my $out, '>', $filename ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# interference
my $command = "$^X $filename 2>&1 |";
open( $out, $command );
is( readline($out), <<'OK', 'no PERSONA, no interference' );
all in Foo
one only
one and two
not one
all in Foo again
OK
open( $out, "PERSONA=zero $command" );
is( readline($out), <<'OK', 'PERSONA zero' );
all in Foo
not one
all in Foo again
OK
open( $out, "PERSONA=one $command" );
is( readline($out), <<'OK', 'PERSONA one' );
all in Foo
one only
one and two
all in Foo again
OK
open( $out, "PERSONA=two $command" );
is( readline($out), <<'OK', 'PERSONA two' );
all in Foo
one and two
not one
all in Foo again
OK

# we're done
ok( unlink($filename), 'remove file' );
