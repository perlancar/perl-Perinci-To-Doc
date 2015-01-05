package Perinci::Sub::To::POD;

# DATE
# VERSION

use 5.010001;
use Log::Any '$log';
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::Sub::To::FuncBase';

sub BUILD {
    my ($self, $args) = @_;
}

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    require Data::Dump;

    my ($self) = @_;

    my $meta  = $self->meta;
    my $dres  = $self->{_doc_res};

    my $has_args = !!keys(%{$dres->{args}});

    $self->add_doc_lines(
        "=head2 " . $dres->{name} .
            ($has_args ? $dres->{args_plterm} : "()").' -> '.$dres->{human_ret},
        "");

    $self->add_doc_lines(
        $dres->{summary}.($dres->{summary} =~ /\.$/ ? "":"."), "")
        if $dres->{summary};

    my $examples = $meta->{examples};
    my $args_as = $meta->{args_as} // 'hash';
    if ($examples && @$examples) {
        $self->add_doc_lines(__("Examples") . ":", "");
        my $i = 0;
        for my $eg (@$examples) {
            $i++;
            my $argsdump;
            if ($eg->{args}) {
                if ($args_as =~ /array/) {
                    require Perinci::Sub::ConvertArgs::Array;
                    my $cares = Perinci::Sub::ConvertArgs::Array::convert_args_to_array(
                        args => $eg->{args}, meta => $meta,
                    );
                    die "Can't convert args to argv in example #$i ".
                        "of function $dres->{name}): $cares->[0] - $cares->[1]"
                            unless $cares->[0] == 200;
                    $argsdump = Data::Dump::dump($cares->[2]);
                    unless ($args_as =~ /ref/) {
                        $argsdump =~ s/^\[\n*//; $argsdump =~ s/,?\s*\]\n?$//;
                    }
                } else {
                    $argsdump = Data::Dump::dump($eg->{args});
                    unless ($args_as =~ /ref/) {
                        $argsdump =~ s/^\{\n*//; $argsdump =~ s/,?\s*\}\n?$//;
                    }
                }
            } elsif ($eg->{argv}) {
                if ($args_as =~ /hash/) {
                    require Perinci::Sub::GetArgs::Argv;
                    my $gares = Perinci::Sub::GetArgs::Argv::get_args_from_argv(
                        argv => $eg->{argv},
                        meta => $meta,
                        per_arg_json => 1,
                        per_arg_yaml => 1,
                    );
                    die "Can't convert argv to args in example #$i ".
                        "of function $dres->{name}): $gares->[0] - $gares->[1]"
                            unless $gares->[0] == 200;
                    $argsdump = Data::Dump::dump($gares->[2]);
                    unless ($args_as =~ /ref/) {
                        $argsdump =~ s/^\{\n*//; $argsdump =~ s/,?\s*\}\n?$//;
                    }
                } else {
                    $argsdump = Data::Dump::dump($eg->{argv});
                    unless ($args_as =~ /ref/) {
                        $argsdump =~ s/^\[\n*//; $argsdump =~ s/,?\s*\]\n?$//;
                    }
                }
            } else {
                $argsdump = '';
            }
            my $out = join(
                "",
                $dres->{name}, "(",
                $argsdump =~ /\n/ ? "\n" : "",
                $argsdump,
                $argsdump =~ /\n/ ? "\n" : "",
                ");",
            );
            my $resdump;
            if (exists $eg->{result}) {
                $resdump = Data::Dump::dump($eg->{result});
            }
            my $status = $eg->{status} // 200;
            my $comment;
            my @expl;
            $out =~ s/^/ /mg;
            # all fits on a single not-too-long line
            if ($argsdump !~ /\n/ &&
                    (!defined($resdump) || $resdump !~ /\n/) &&
                        length($argsdump) + length($resdump // "") < 80) {
                if ($status == 200) {
                    $comment = "-> $resdump" if defined $resdump;
                } else {
                    $comment = "ERROR $status";
                }
            } else {
                push @expl, "Result: C<< $resdump >>." if defined($resdump);
            }
            push @expl, ($eg->{summary} . ($eg->{summary} =~ /\.$/ ? "" : "."))
                if $eg->{summary};
            # XXX example's description

            $self->add_doc_lines(
                $out . (defined($comment) ? " # $comment" : ""),
                ("", "") x !!@expl,
                @expl,
                ("", "") x !!@expl,
            );
        }
    }

    $self->add_doc_lines($self->_md2pod($dres->{description}), "")
        if $dres->{description};

    my $feat = $meta->{features} // {};
    my @ft;
    my %spargs;
    if ($feat->{reverse}) {
        push @ft, __("This function supports reverse operation.");
        $spargs{-reverse} = {
            type => 'bool',
            summary => __("Pass -reverse=>1 to reverse operation."),
        };
    }
    # undo is deprecated now in Rinci 1.1.24+, but we still support it
    if ($feat->{undo}) {
        push @ft, __("This function supports undo operation.");
        $spargs{-undo_action} = {
            type => 'str',
            summary => __(
                "To undo, pass -undo_action=>'undo' to function. ".
                "You will also need to pass -undo_data. ".
                "For more details on undo protocol, ".
                "see L<Rinci::Undo>."),
        };
        $spargs{-undo_data} = {
            type => 'array',
            summary => __(
                "Required if you pass -undo_action=>'undo'. ".
                "For more details on undo protocol, ".
                "see L<Rinci::function::Undo>."),
        };
    }
    if ($feat->{dry_run}) {
        push @ft, __("This function supports dry-run operation.");
        $spargs{-dry_run} = {
            type => 'bool',
            summary=>__("Pass -dry_run=>1 to enable simulation mode."),
        };
    }
    push @ft, __("This function is pure (produce no side effects).")
        if $feat->{pure};
    push @ft, __("This function is immutable (returns same result ".
                     "for same arguments).")
        if $feat->{immutable};
    push @ft, __("This function is idempotent (repeated invocations ".
                     "with same arguments has the same effect as ".
                         "single invocation).")
        if $feat->{idempotent};
    if ($feat->{tx}) {
        die "Sorry, I only support transaction protocol v=2"
            unless $feat->{tx}{v} == 2;
        push @ft, __("This function supports transactions.");
        $spargs{$_} = {
            type => 'str',
            summary => __(
                "For more information on transaction, see ".
                "L<Rinci::Transaction>."),
        } for qw(-tx_action -tx_action_id -tx_v -tx_rollback -tx_recovery),
    }
    $self->add_doc_lines(join(" ", @ft), "", "") if @ft;

    if ($has_args) {
        $self->add_doc_lines(
            __("Arguments") .
                ' (' . __("'*' denotes required arguments") . '):',
            "",
            "=over 4",
            "",
        );
        for my $name (sort keys %{$dres->{args}}) {
            my $ra = $dres->{args}{$name};
            $self->add_doc_lines(join(
                "",
                "=item * B<", $name, ">",
                ($ra->{arg}{req} ? '*' : ''), ' => ',
                "I<", $ra->{human_arg}, ">",
                (defined($ra->{human_arg_default}) ?
                     " (" . __("default") .
                         ": $ra->{human_arg_default})" : "")
            ), "");
            $self->add_doc_lines(
                $ra->{summary} . ($ra->{summary} =~ /\.$/ ? "" : "."),
                "") if $ra->{summary};
            $self->add_doc_lines(
                $self->_md2pod($ra->{description}),
                "") if $ra->{description};
        }
        $self->add_doc_lines("=back", "");
    } else {
        $self->add_doc_lines(__("No arguments") . ".", "");
    }

    if (keys %spargs) {
        $self->add_doc_lines(
            __("Special arguments") . ":",
            "",
            "=over 4",
            "",
        );
        for my $name (sort keys %spargs) {
            my $spa = $spargs{$name};
            $self->add_doc_lines(join(
                "",
                "=item * B<", $name, ">",
                ' => ',
                "I<", $spa->{type}, ">",
                (defined($spa->{default}) ?
                     " (" . __("default") .
                         ": $spa->{default})" : "")
            ), "");
            $self->add_doc_lines(
                $spa->{summary} . ($spa->{summary} =~ /\.$/ ? "" : "."),
                "") if $spa->{summary};
        }
        $self->add_doc_lines("=back", "");
    }

    my $rn = $meta->{result_naked};
    $self->add_doc_lines($self->_md2pod(__(
"Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.")), "")
         unless $rn;

    $self->add_doc_lines(__("Return value") . ': ' .
                         ($dres->{res_summary} // "") . " ($dres->{human_res})",
                         "");
    $self->add_doc_lines("", $self->_md2pod($dres->{res_description}), "")
        if $dres->{res_description};

    if ($meta->{links} && @{ $meta->{links} }) {
        $self->add_doc_lines(__("See also") . ":", "", "=over", "");
        for my $link (@{ $meta->{links} }) {
            my $url = $link->{url};
            # currently only handles pm: urls (link to another perl module)
            next unless $url =~ m!\Apm:(?://)?(.+)!;
            my $mod = $1;
            $self->add_doc_lines("* L<$mod>", "");
            $self->add_doc_lines($link->{summary}.".", "") if $link->{summary};
            $self->add_doc_lines($self->_md2pod($link->{description}), "") if $link->{description};
        }
        $self->add_doc_lines("=back", "");
    }
}

1;
# ABSTRACT: Generate POD documentation from Rinci function metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

You can use the included L<peri-doc> script, or:

 use Perinci::Sub::To::POD;
 my $doc = Perinci::Sub::To::POD->new(url => "/Some/Module/somefunc");
 say $doc->gen_doc;


=head1 SEE ALSO

L<Perinci::To::POD> to generate POD documentation for the whole package.

=cut
