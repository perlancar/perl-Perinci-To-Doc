package Perinci::To::POD;

# DATE
# VERSION

use 5.010001;
use Log::Any::IfLOG '$log';
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::To::PackageBase';

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
    my %args = @_;

    my $o = Perinci::Sub::To::POD->new(
        _pa => $self->{_pa},
        export => $self->{exports} ? $self->{exports}{$args{name}} : undef,
        %args,
    );
    $o->gen_doc;
    $o->doc_lines;
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::POD;

    my ($self) = @_;
    my $dres = $self->{_doc_res};

    $self->add_doc_lines(
        "=head1 " . uc(__("Functions")),
    );

    $self->SUPER::gen_doc_section_functions;

    # XXX categorize functions based on tags?
    for my $furi (sort keys %{ $dres->{functions} }) {
        $self->add_doc_lines("");
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines($_);
        }
    }
}

sub gen_doc_section_links {
    my $self = shift;

    my %seen_urls;
    my $meta = $self->meta;
    my $child_metas = $self->child_metas;

    my @links;
    push @links, @{ $meta->{links} } if $meta->{links};
    for my $m (values %$child_metas) {
        push @links, @{ $m->{links} } if $m->{links};
    }

    if (@links) {
        $self->add_doc_lines("=head1 " . __("SEE ALSO"), "");
        for my $link0 (@links) {
            my $link = ref($link0) ? $link0 : {url=>$link0};
            my $url = $link->{url};
            next if $seen_urls{$url}++;
            $url =~ s!\A(pm|pod|prog):(//?)?!!;
            $self->add_doc_lines(
                "L<$url>." .
                    ($link->{summary} ? " $link->{summary}." : "") .
                    ($link->{description} ? " " . $self->_md2pod($link->{description}) : ""),
                "");
        }
    }
}

1;
# ABSTRACT: Generate POD documentation for a package from Rinci metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

You can use the included L<peri-doc> script, or:

 use Perinci::To::POD;
 my $doc = Perinci::To::POD->new(
     name=>"Foo::Bar", meta => {...}, child_metas => {...});
 say $doc->gen_doc;

To generate documentation for a single function, see L<Perinci::Sub::To::POD>.

To generate a usage-like help message for a single function, you can try the
L<peri-func-usage> from the L<Perinci::CmdLine::Classic> distribution.

=cut
