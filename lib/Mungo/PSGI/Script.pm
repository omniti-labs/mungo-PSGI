package Mungo::PSGI::Script;
# ABSTRACT: Mungo script
use strict;
use warnings;
# VERSION
use Package::Stash ();
use SelectSaver ();
use Data::Dumper ();
use Mungo::PSGI::Script::Memory;
use Mungo::PSGI::Script::File;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->_parse;
    return $self;
}

my $package_inc = 0;
sub _package {
    return $_[0]->{package}
        ||= sprintf '%s::__ASP_%s__', __PACKAGE__, ++$package_inc;
}
sub code { $_[0]->{code} }
sub timestamp { $_[0]->{timestamp} }

sub up_to_date { 1 }

sub fetch {
    my $class = shift;
    my $file = shift;
    my $reload = shift;
    if ( ref $file ) {
        my $content = $$file;
        return Mungo::PSGI::Script::Memory->fetch($$file, $reload);
    }
    else {
        return Mungo::PSGI::Script::File->fetch($file, $reload);
    }
}

sub _parse {
    my $self = shift;

    my $content = $self->content;

    $self->{code} = $self->_code_gen($content);
    $self->{timestamp} = time;

    return 1;
}

sub stacktrace {
    my $class = shift;
    my $err = '';
    my $clevel = 2;
    while (my @caller = caller($clevel++)) {
        my ($package, $filename, $line) = @caller;
        my $prefix = __PACKAGE__ . '::__ASP_';
        if ($package =~ /^$prefix\d+__$/) {
            $err .= "  called at $filename line $line\n";
        }
    }
    return $err;
}

sub DESTROY {
    my $self = shift;
    $self->_clear_package;
}

sub _clear_package {
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

    my $code = eval sprintf <<'END_CODE', $self->_package, $self->file, $self->_transform_code(shift);
my $script = $self;
package %s;
sub code {
my $Request = $script->{Request};
my $Server = $Request->Server;
my $Response = $Request->Response;
my $__saver = SelectSaver->new($Response->as_handle);

#line 1 %s
%s
}
\&code
END_CODE
    if (! $code) {
        die $@;
    }
    $self->{code} = $code;
}

sub _transform_code {
    my $self = shift;
    my $string = shift;

    my $out = '';
    my @chunks = split /<%([~=]?)(.*?)%>/, $string;
    # chunks will be <plain text>, <ASP block type>, <ASP Code>, <plain text>
    while (@chunks) {
        my $plain = shift @chunks;
        # push internationalization calls on as ASP prints
        if ($plain =~ s/I\[\[(.*?)\]\](.*)//s) {
            unshift @chunks, '=', '$Response->i18n(' . $1 . ')', $2;
        }
        # convert plain text to perl string code, add as print
        if ($plain ne '') {
            local $Data::Dumper::Terse = 1;
            local $Data::Dumper::Useqq = 0;
            $plain = Data::Dumper::Dumper($plain);
            chomp $plain;
            $out .= "\$Response->print($plain);";
        }
        last
            if ! @chunks;
        # marker indicates ASP block type, or empty
        my ($marker, $code) = (shift @chunks, shift @chunks);
        if ($marker eq '=') {
            $out .= "\$Response->print($code);";
        }
        elsif ($marker eq '~') {
            $out .= "\$Response->print(HTML::Entities::encode_entities($code));";
        }
        else {
            $out .= $code . ';';
        }
    }
    return $out;
}

sub run {
    my $self = shift;
    local $self->{Request} = shift;

    $self->code->(@_);
}

1;

