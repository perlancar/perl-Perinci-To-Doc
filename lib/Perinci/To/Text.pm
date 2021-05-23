package Perinci::To::Text;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::To::PackageBase';
with    'Perinci::To::Doc::Role::Section::AddTextLines';

sub BUILD {
    my ($self, $args) = @_;
}

sub gen_doc_section_summary {
    my ($self) = @_;

    #my $meta = $self->meta;
    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_summary;

    my $name_summary = join(
        "",
        $dres->{name} // "",
        ($dres->{name} && $dres->{summary} ? ' - ' : ''),
        $dres->{summary} // ""
    );

    $self->add_doc_lines(uc(__("Name")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($name_summary);
    $self->dec_doc_indent;
}

sub gen_doc_section_version {
    my ($self) = @_;

    my $meta = $self->meta;
    #my $dres = $self->{_doc_res};

    $self->add_doc_lines("", uc(__("Version")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($meta->{entity_v} // '?');
    $self->dec_doc_indent;
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->SUPER::gen_doc_section_description;
    return unless $dres->{description};

    $self->add_doc_lines("", uc(__("Description")), "");

    $self->inc_doc_indent;
    $self->add_doc_lines($dres->{description});
    $self->dec_doc_indent;
}

sub _gen_func_doc {
    my $self = shift;
    my $o = Perinci::Sub::To::Text->new(_pa=>$self->{_pa}, @_);
    $o->gen_doc;
    $o->doc_lines;
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::Text;

    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->add_doc_lines("", uc(__("Functions")), "");
    $self->SUPER::gen_doc_section_functions;
    my $i;
    for my $furi (sort keys %{ $dres->{functions} }) {
        $self->add_doc_lines('') if $i++;
        my $meta = $dres->{function_metas}{$furi};
        next if ($meta->{is_meth} || $meta->{is_class_meth}) && !($meta->{is_func} // 1);
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines({wrap=>0}, $_);
        }
    }
    $self->add_doc_lines('');
}

sub gen_doc_section_methods {
    require Perinci::Sub::To::Text;

    my ($self) = @_;

    my $dres = $self->{_doc_res};

    $self->add_doc_lines("", uc(__("Methods")), "");
    $self->SUPER::gen_doc_section_methods;
    my $i;
    for my $furi (sort keys %{ $dres->{functions} }) {
        $self->add_doc_lines('') if $i++;
        my $meta = $dres->{function_metas}{$furi};
        next unless ($meta->{is_meth} || $meta->{is_class_meth}) && !($meta->{is_func} // 1);
        for (@{ $dres->{functions}{$furi} }) {
            chomp;
            $self->add_doc_lines({wrap=>0}, $_);
        }
    }
    $self->add_doc_lines('');
}

1;
# ABSTRACT: Generate text documentation for a package from Rinci metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Perinci::To::POD;
 my $doc = Perinci::To::Text->new(
     name=>'Foo::Bar', meta => {...}, child_metas=>{...});
 say $doc->gen_doc;

You can also try the L<peri-doc> script with the C<--format text> option:

 % peri-doc --format text /Some/Module/

To generate a usage-like help message for a single function, you can try the
L<peri-func-usage> from the L<Perinci::CmdLine::Classic> distribution.

=cut
