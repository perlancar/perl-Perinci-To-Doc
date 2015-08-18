package Perinci::Sub::To::FuncBase;

# DATE
# VERSION

use 5.010;
use Log::Any::IfLOG '$log';
use Moo;

use Data::Dump::OneLine qw(dump1);
use Data::Sah::Terse qw(terse_schema);
use Perinci::Object;
use Perinci::Sub::Normalize qw(normalize_function_metadata);

with 'Perinci::To::Doc::Role::Section';

has meta => (is=>'rw');
has name => (is=>'rw');

sub BUILD {
    my ($self, $args) = @_;

    $args->{meta} or die "Please specify meta";

    $self->{doc_sections} //= [
        'summary',
        'description',
        'arguments',
        'result',
        'examples',
        'links',
    ];
}

sub before_gen_doc {
    my ($self, %opts) = @_;
    $log->tracef("=> FuncBase's before_gen_doc(opts=%s)", \%opts);

    $self->{meta} = normalize_function_metadata($self->{meta});

    # initialize hash to store [intermediate] result
    $self->{_doc_res} = {};
}

# provide simple default implementation without any text wrapping. subclass such
# as Perinci::Sub::To::Text will use another implementation, one that supports
# text wrapping for example (provided by
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

    my $name = $self->name // $rimeta->langprop("name") //
        "unnamed_function";
    my $summary = $rimeta->langprop("summary");

    $dres->{name}    = $name;
    $dres->{summary} = $summary;
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $rimeta = rimeta($self->meta);
    my $dres   = $self->{_doc_res};

    $dres->{description} = $rimeta->langprop("description");
}

sub gen_doc_section_arguments {
    my ($self) = @_;

    my $meta   = $self->meta;
    my $rimeta = rimeta($meta);
    my $dres   = $self->{_doc_res};
    my $args_p = $meta->{args} // {};

    # perl term for args, whether '$arg1, $arg2, ...', or '%args', etc
    my $aa = $meta->{args_as} // 'hash';
    my $aplt;
    if (!keys(%$args_p)) {
        $aplt = '()';
    } elsif ($aa eq 'hash') {
        $aplt = '(%args)';
    } elsif ($aa eq 'hashref') {
        $aplt = '(\%args)';
    } elsif ($aa =~ /\Aarray(ref)?\z/) {
        $aplt = join(
            '',
            '(',
            ($aa eq 'arrayref' ? '[' : ''),
            join(', ',
                 map {
                     my $var = $_; $var =~ s/[^A-Za-z0-9_]+/_/g;
                     "\$$var" . ($args_p->{$_}{greedy} ? ', ...' : '');
                 }
                     sort {
                         ($args_p->{$a}{pos} // 9999) <=>
                             ($args_p->{$b}{pos} // 9999)
                         } keys %$args_p),
            ($aa eq 'arrayref' ? ']' : ''),
            ')'
        );
    } else {
        die "BUG: Unknown value of args_as '$aa'";
    }
    $dres->{args_plterm} = $aplt;

    my $args  = $meta->{args} // {};
    $dres->{args} = {};
    my $raa = $dres->{args};
    for my $name (keys %$args) {
        my $arg = $args->{$name};
        my $riargmeta = rimeta($arg);
        $arg->{default_lang} //= $meta->{default_lang};
        $arg->{schema} //= ['any'=>{}];
        my $s = $arg->{schema};
        my $ra = $raa->{$name} = {schema=>$s};
        $ra->{human_arg} = terse_schema($s);
        if (exists $arg->{default}) {
            $ra->{human_arg_default} = dump1($arg->{default});
        } elsif (defined $s->[1]{default}) {
            $ra->{human_arg_default} = dump1($s->[1]{default});
        }
        $ra->{summary}     = $riargmeta->langprop('summary');
        $ra->{description} = $riargmeta->langprop('description');
        $ra->{arg}         = $arg;

        $raa->{$name} = $ra;
    }
}

sub gen_doc_section_result {
    my ($self) = @_;

    my $meta      = $self->meta;
    my $riresmeta = rimeta($meta->{result});
    my $dres      = $self->{_doc_res};

    $dres->{res_schema} = $meta->{result} ? $meta->{result}{schema} : undef;
    $dres->{res_schema} //= [any => {}];
    $dres->{human_res} = terse_schema($dres->{res_schema});

    my $rn = $meta->{result_naked};
    if ($rn) {
        $dres->{human_ret} = $dres->{human_res};
    } else {
        $dres->{human_ret} = '[status, msg, result, meta]';
    }

    $dres->{res_summary}     = $riresmeta->langprop("summary");
    $dres->{res_description} = $riresmeta->langprop("description");
}

sub gen_doc_section_examples {
    # not yet
}

sub gen_doc_section_links {
    # not yet
}

1;
# ABSTRACT: Base class for Perinci::Sub::To::* function documentation generators

=for Pod::Coverage .+
