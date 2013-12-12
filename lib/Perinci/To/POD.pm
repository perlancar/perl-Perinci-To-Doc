package Perinci::To::POD;

use 5.010001;
use Log::Any '$log';
use Moo;

use Locale::TextDomain 'Perinci-To-POD';

extends 'Perinci::To::PackageBase';

# VERSION

sub BUILD {
    my ($self, $args) = @_;
}

sub _md2pod {
    require Markdown::Pod;

    my ($self, $md) = @_;
    state $m2p = Markdown::Pod->new;
    $m2p->markdown_to_pod(markdown => $md);
}

sub gen_doc_section_summary {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_summary;

    my $name_summary = join(
        "",
        $dres->{name} // "",
        ($dres->{name} && $dres->{summary} ? ' - ' : ''),
        $dres->{summary} // ""
    );

    $self->add_doc_lines(
        "=head1 " . uc(__("Name")),
        "",
        $name_summary,
        "",
    );
}

sub gen_doc_section_version {
    my ($self) = @_;

    my $meta = $self->meta;

    $self->add_doc_lines(
        "=head1 " . uc(__("Version")),
        "",
        $meta->{entity_v} // '?',
        "",
    );
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Description")),
        ""
    );

    $self->SUPER::gen_doc_section_description;

    if ($dres->{description}) {
        $self->add_doc_lines(
            $self->_md2pod($dres->{description}),
            "",
        );
    }

    #$self->add_doc_lines(
    #    __("This module has L<Rinci> metadata") . ".",
    #    "",
    #);
}

sub _gen_func_doc {
    my $self = shift;
    my $o = Perinci::Sub::To::POD->new(@_);
    $o->gen_doc;
    $o->doc_lines;
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::POD;

    my ($self) = @_;
    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Functions")),
        "",
    );

    $self->SUPER::gen_doc_section_functions;

    # XXX if module uses Perinci::Exporter, show a basic usage for importing and
    # show exportability information

    # XXX categorize functions based on tags?
    for my $furi (sort keys %{ $dres->{functions} }) {
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines($_);
        }
    }
}

1;
# ABSTRACT: Generate POD documentation for a package from Rinci metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

You can use the included L<peri-pkg-doc> script, or:

 use Perinci::To::POD;
 my $doc = Perinci::To::POD->new(
     name=>"Foo::Bar", meta => {...}, child_metas => {...});
 say $doc->gen_doc;

To generate documentation for a single function, see L<Perinci::Sub::To::POD> or
the provided command-line script L<peri-func-doc>.

To generate a usage-like help message for a single function, you can try
the L<peri-func-usage> from the L<Perinci::CmdLine> distribution.

=cut
