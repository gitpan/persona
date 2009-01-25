BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

# set up tests to do
use Test::More tests => 3 + 1 + 2 + 2 + 2 + 1;

# strict and verbose as possible
use strict;
use warnings;

# does it compile?
BEGIN { use_ok( 'persona' ) }

# set up source to check
my $module = 'Foo';
my $source = <<"SRC";
all
#PERSONA one
one only
#PERSONA one two
one and two
#PERSONA !one
not one
#PERSONA
all again
__END__
#PERSONA one
one never
#PERSONA
all never
SRC

# make sure we have it as a file
my $filename = "$module.pm";
open( my $out, '>', $filename ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# set up string components
my $prefix  =
  qq/$^X -Mpersona -e 'print scalar \${ persona->path2source("$filename/;
my $postfix =
  qq/") }' 2>&1 |/;

# no persona
open( $out, "$prefix$postfix" );
is( readline($out), $source, 'no persona, no interference' );

# persona zero
foreach ( qq{PERSONA=zero $prefix$postfix}, qq{$prefix","zero$postfix} ) {
    open( $out, $_ );
    is( readline($out), <<'OK', 'PERSONA zero' );
all
#line 7 Foo.pm (all but persona 'one')
not one
#PERSONA
all again
__END__
#PERSONA one
one never
#PERSONA
all never
OK
}

# persona one
foreach ( qq{PERSONA=one $prefix$postfix}, qq{$prefix","one$postfix} ) {
    open( $out, $_ );
    is( readline($out), <<'OK', 'PERSONA one' );
all
#PERSONA one
one only
#PERSONA one two
one and two
#line 9 Foo.pm (all personas)
all again
__END__
#PERSONA one
one never
#PERSONA
all never
OK
}

# persona two
foreach ( qq{PERSONA=two $prefix$postfix}, qq{$prefix","two$postfix} ) {
    open( $out, $_ );
    is( readline($out), <<'OK', 'PERSONA two' );
all
#line 5 Foo.pm (allowed by persona 'two')
one and two
#PERSONA !one
not one
#PERSONA
all again
__END__
#PERSONA one
one never
#PERSONA
all never
OK
}

# we're done
ok( unlink($filename), 'remove module' );
