package Mungo::PSGI::Script;
# ABSTRACT: Mungo script

# don't want any variables or pragmas to leak into generated subs
sub _eval { eval shift or die $@ }

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
    my $source = $self->_transform_code(shift);
    my $package = $self->_package;
    my $file = $self->file;

    my $full_source = sprintf <<'END_CODE', $package, $file, $source;
package %s;
use warnings FATAL => qw(closure deprecated redefine severe syntax void);
sub {
local our $Request = shift;
local our $Server = $Request->Server;
local our $Response = $Request->Response;
$Request->use_globals
    and local $::Request = $Request
    and local $::Server = $Server
    and local $::Response = $Response
;
# hide saver in a lexical, then re-alias the var back to global
# prevents introducing an additional var
my $_ = SelectSaver->new($Response->as_handle);
{ our $_;
#line 1 %s
%s
}
}
END_CODE
    return _eval($full_source);
}

sub _string_as_code {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 0;
    my $plain = Data::Dumper::Dumper(shift);
    chomp $plain;
    return $plain;
}

sub _transform_code {
    my $self = shift;
    my $string = shift;

    my $out = '';
    while ($string =~ /\G(.*?)(?=<%|\z)/msxgc) {
        my $plain = $1;
        while ($plain =~ m{
            \G (.*?)
            (?:
                \QI[[\E (.*?) \Q]]\E
            |
                \z
            )
        }msxgc) {
            my $i18n = $2;
            if ($1 ne '') {
                $out .= '$Response->print(' . _string_as_code("$1") . ');';
            }
            if (defined $i18n) {
                $out .= '$Response->print($Response->i18n(' . _string_as_code("$1") . '));';
            }
        }
        last
            if pos $string >= length $string;

        if ($string =~ /\G<%/msxgc) {
            if ($string =~ /\G([=~]?)(.*?)%>/msxgc) {
                my ($marker, $code) = ($1, $2);
                if ($marker eq '') {
                    $out .= $code . ';';
                }
                elsif ($marker eq '=') {
                    $out .= '$Response->print(do{' . $code . '});';
                }
                elsif ($marker eq '~') {
                    $out .= '$Response->print(HTML::Entities::encode_entities(do{' . $code . '}));';
                }
            }
            else {
                my $startpos = pos($string) - 2;

                my $pre = substr $string, 0, $startpos;
                my $lines = $pre =~ tr/\n/\n/ + 1;

                my $section = substr $string, $startpos, 20;
                $section =~ s/\n/\\n/g;
                $section .= '...';

                die "Can't find end of ASP section '$section' at line $lines";
            }
        }
    }
    return $out;
}

sub run {
    my $self = shift;
    goto $self->code;
}

1;

