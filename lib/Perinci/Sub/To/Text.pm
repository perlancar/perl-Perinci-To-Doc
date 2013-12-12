package Perinci::Sub::To::Text;

use 5.010001;
use Log::Any '$log';
use Moo;

use Locale::TextDomain 'Perinci-Sub-To-Text';

extends 'Perinci::Sub::To::FuncBase';
with    'SHARYANTO::Role::Doc::Section::AddTextLines';

# VERSION

sub BUILD {
    my ($self, $args) = @_;
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    my ($self) = @_;

    my $meta  = $self->meta;
    my $dres  = $self->{_doc_res};

    $self->add_doc_lines(
        "+ ".$dres->{name}.$dres->{args_plterm}.' -> '.$dres->{human_ret},
    );
    $self->inc_doc_indent;

    $self->add_doc_lines("", $dres->{summary})     if $dres->{summary};
    $self->add_doc_lines("", $dres->{description}) if $dres->{description};
    if (keys %{$dres->{args}}) {
        $self->add_doc_lines(
            "",
            __("Arguments") .
                ' (' . __("'*' denotes required arguments") . '):',
            "");
        my $i = 0;
        my $arg_has_ct;
        for my $name (sort keys %{$dres->{args}}) {
            my $prev_arg_has_ct = $arg_has_ct;
            $arg_has_ct = 0;
            my $ra = $dres->{args}{$name};
            $self->add_doc_lines("") if $i++ > 0 && $prev_arg_has_ct;
            $self->add_doc_lines(join(
                "",
                "- ", $name, ($ra->{arg}{req} ? '*' : ''), ' => ',
                $ra->{human_arg},
                (defined($ra->{human_arg_default}) ?
                     " (" . __("default") .
                         ": $ra->{human_arg_default})" : "")
            ));
            if ($ra->{summary} || $ra->{description}) {
                $arg_has_ct++;
                $self->inc_doc_indent(2);
                $self->add_doc_lines($ra->{summary}.".") if $ra->{summary};
                if ($ra->{description}) {
                    $self->add_doc_lines("", $ra->{description});
                }
                $self->dec_doc_indent(2);
            }
        }
    }

    if ($meta->{dies_on_error}) {
        $self->add_doc_lines("", __("This function dies on error."), "");
    }

    $self->add_doc_lines("", __("Return value") . ':');
    $self->inc_doc_indent;
    my $rn = $meta->{result_naked};
    $self->add_doc_lines(__(
"Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information."))
        unless $rn;
    $self->dec_doc_indent;

    $self->dec_doc_indent;
}

1;
# ABSTRACT: Generate text documentation from Rinci function metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Perinci::Sub::To::Text;

 my $doc = Perinci::Sub::To::Text->new(meta => {...});
 say $doc->gen_doc;

You can also try the L<peri-func-doc> script (included in the
L<Perinci::Sub::To::POD> distribution) with the C<--format text> option:

 % peri-func-doc --format text /Some/Module/somefunc

To generate a usage-like help message for a function, you can try
L<peri-func-usage> which is included in the L<Perinci::CmdLine> distribution.

 % peri-func-usage http://example.com/api/somefunc

=cut
