package Perinci::ToUtil;

use 5.010;
use strict;
use warnings;

# VERSION

# generate human-readable short description of schema, this will be
# handled in the future by Sah itself (using the human compiler).

sub sah2human_short {
    require Data::Sah;
    require List::MoreUtils;

    my ($s) = @_;
    if ($s->[0] eq 'any') {
        my @alts    = map {Data::Sah::normalize_schema($_)}
            @{$s->[1]{of} // []};
        my @types   = map {$_->[0]} @alts;
        @types      = sort(List::MoreUtils::uniq(@types));
        return join("|", @types) || 'any';
    } else {
        return $s->[0];
    }
}

1;
# ABSTRACT: Temporary utility module

=head1 FUNCTIONS

=head2 sah2human_short

=cut
