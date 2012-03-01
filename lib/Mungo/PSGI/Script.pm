package Mungo::PSGI::Script;
# ABSTRACT: Mungo script file
use strict;
use warnings;
# VERSION
use Cwd ();
use Sub::Quote qw(quote_sub);
use Package::Stash ();
use SelectSaver ();
use Data::Dumper ();

sub new {
    my $class = shift;
    my $file = shift;
    my $self = bless {
        file => $file,
    }, $class;
    $self->_parse;
    return $self;
}

my %file_objects;
sub fetch {
    my $class = shift;
    my $file = Cwd::abs_path(shift);
    my $reload = shift;
    my $script = $file_objects{$file};
    if ($script && $reload && $script->file_timestamp > $script->timestamp) {
        $script = $file_objects{$file} = undef;
    }
    if (!$script) {
        $script = $file_objects{$file} = $class->new($file);
    }
    return $script;
}

sub _package {
    my $self = shift;
    return $self->{package};
}

my $package_inc = 0;
sub _parse {
    my $self = shift;
    my $package = sprintf __PACKAGE__ . '::__ASP_%s__', ++$package_inc;
    $self->{package} = $package;

    my $file = $self->file;
    open my $fh, '<', $file or die "Can't read $file: $!";
    my $contents = do { local $/; <$fh> };
    close $fh;
    $self->_code_gen($contents);

    $self->{timestamp} = $self->file_timestamp;
    return 1;
}

sub DESTROY {
    my $self = shift;
    my $package = $self->_package;
    return
        unless $package;
    my $stash = Package::Stash->new($package);
    for my $symbol ($stash->list_all_symbols) {
        $stash->remove_symbol($symbol);
    }
}

sub _code_gen {
    my $self = shift;
    my $content = shift;

    my $script_code = $self->_transform_code($content);
    my $package = $self->_package;

    $script_code = <<"END_CODE" . $script_code;
        my \$Request = \$script->{Request};
        my \$Server = \$Request->{Server};
        my \$Response = \$Request->{Response};
        package $package;
END_CODE
    my $code = quote_sub $package . '::code', $script_code, { '$script' => \$self }, { no_install => 1 };
    $self->{code} = $code;
}

sub _string_as_i18n {
    return ''
        unless length $_[0];
    my $s = Data::Dumper::Dumper($_[0]);
    substr $s, 0, 7, '<%= $main::Response->i18n(';
    substr $s, -2, 2, ') %>';
    return $s;
}

sub _string_as_print {
    return ''
        unless length $_[0];
    my $s = Data::Dumper::Dumper($_[0]);
    substr $s, 0, 7, 'print';
    return $s;
}

sub _transform_code {
    my $self = shift;
    my $string = shift;

    $string =~ s/I\[\[(.*?)\]\]/_string_as_i18n($1)/seg;
    $string =~ s/^(.*?)(?=<%|$)/_string_as_print($1)/se;
    # Replace non-code
    $string =~ s/(?<=%>)(?!<%)(.*?)(?=<%|$)/_string_as_print($1)/seg;
    # fixup code
    $string =~ s{
        <%([~=]?)(.*?)%>
    }{
          ($1 eq '~')   ? "print HTML::Entities::encode_entities($2,'<&>\"');"
        : ($1 eq '=')   ? "print $2;"   # This is <%= ... %>
                        : "$2;"         # This is <% ... %>
    }sexg;
    return $string;
}

sub code {
    my $self = shift;
    return $self->{code};
}

sub file {
    my $self = shift;
    return $self->{file};
}

sub timestamp {
    my $self = shift;
    return $self->{timestamp};
}

sub file_timestamp {
    my $self = shift;
    my $timestamp = (stat Cwd::abs_path($self->file))[9];
    return $timestamp;
}

sub run {
    my $self = shift;
    $self->{Request} = shift;
    my $resp = $self->{Request}->Response;

    my $b = '';
    open my $io, '>', \$b;

    tie *$io, ref $resp, $resp;
    my $saver = SelectSaver->new($io);

    $self->code->();
}

1;

