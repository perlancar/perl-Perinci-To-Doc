package Perinci::ToUtil;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

sub sah2human_short {
    require Data::Sah::Normalize;
    require Function::Fallback::CoreOrPP;

    my ($s) = @_;
    if ($s->[0] eq 'any') {
        my @alts    = map {Data::Sah::Normalize::normalize_schema($_)}
            @{$s->[1]{of} // []};
        my @types   = map {$_->[0]} @alts;
        @types      = sort(Function::Fallback::CoreOrPP::uniq(@types));
        return join("|", @types) || 'any';
    } else {
        return $s->[0];
    }
}

1;
# ABSTRACT: Temporary utility module

=head1 SYNOPSIS

 use Perinci::ToUtil qw(sah2human_short);

 say sah2human_short("int"); # -> int
 say sah2human_short(["int", {req=>1, min=>0}]); # -> int
 say sah2human_short(["any", of=>["int*", [array=>of=>'int*']]]); # -> int|array


=head1 FUNCTIONS

=head2 sah2human_short($sch) -> str

Generate human-readable short description of schema, basically just type name
(e.g. C<int>) or a list of type names (e.g. C<code|hash>). This is a temporary
function and will be handled in the future by L<Data::Sah> using the human
compiler.

=cut
