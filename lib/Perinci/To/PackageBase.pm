package Perinci::To::PackageBase;

# DATE
# VERSION

use 5.010;
use Data::Dump::OneLine qw(dump1);
use Log::Any::IfLOG '$log';
use Moo;
use Perinci::Object;

with 'Perinci::To::Doc::Role::Section';

has name => (is=>'rw');
has meta => (is=>'rw');
has url  => (is=>'rw');
has child_metas => (is=>'rw');
has _pa => (is=>'rw');

sub BUILD {
    my ($self, $args) = @_;

    $args->{meta} or die "Please specify meta";
    $args->{child_metas} or die "Please specify child_metas";
    $self->{doc_sections} //= [
        'summary',
        'version',
        'description',
        'functions',
        'links',
    ];
    $self->{_pa} //= do {
        require Perinci::Access;
        Perinci::Access->new;
    };
}

sub before_gen_doc {
    my ($self, %opts) = @_;
    $log->tracef("=> PackageBase's before_gen_doc(opts=%s)", \%opts);

    # initialize hash to store [intermediate] result
    $self->{_doc_res} = {};
}

# provide simple default implementation without any text wrapping. subclass such
# as Perinci::To::Text will use another implementation, one that supports text
# wrapping for example (provided by
# Perinci::To::Doc::Role::Section::AddTextLines).
sub add_doc_lines {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') { $opts = shift }
    $opts //= {};

    my @lines = map { $_ . (/\n\z/s ? "" : "\n") }
        map {/\n/ ? split /\n/ : $_} @_;

    my $indent = $self->doc_indent_str x $self->doc_indent_level;
    push @{$self->doc_lines},
        map {"$indent$_"} @lines;
}

sub gen_doc_section_summary {
    my ($self) = @_;

    my $rimeta = rimeta($self->meta);
    my $dres   = $self->{_doc_res};

    my $name = $self->name // $rimeta->langprop("name") // "UnnamedModule";
    my $summary = $rimeta->langprop("summary");

    $dres->{name}    = $name;
    $dres->{summary} = $summary;
}

sub gen_doc_section_version {
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $rimeta = rimeta($self->meta);
    my $dres   = $self->{_doc_res};

    $dres->{description} = $rimeta->langprop("description");
}

sub gen_doc_section_functions {
    require Perinci::Sub::To::FuncBase;

    my ($self) = @_;

    my $cmetas = $self->child_metas;
    my $dres   = $self->{_doc_res};

    # list all functions
    my @func_uris = grep {m!(\A|/)\w+\z!} sort keys %$cmetas;

    # generate doc for all functions
    $dres->{functions} = {};
    $dres->{function_names_by_meta_addr} = {};
    for my $furi (@func_uris) {
        my $fname = $furi; $fname =~ s!.+/!!;
        my $meta = $cmetas->{$furi};
        next if $meta->{'x.no_index'};
        push @{ $dres->{function_names_by_meta_addr}{"$meta"} }, $fname;
        $dres->{functions}{$furi} =
            $self->_gen_func_doc(
                parent=>$self,
                name=>$fname,
                meta=>$meta,
                url=>"$self->{url}$furi",
            );
    }
}

sub gen_doc_section_links {
}

1;
# ABSTRACT: Base class for Perinci::To::* package documentation generators

=for Pod::Coverage .+
