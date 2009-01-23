require 5.008;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "persona",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'persona - control which code will be loaded for a persona',
 VERSION_FROM	=> 'lib/persona.pm',
 PREREQ_PM	=> {
                   },
);
