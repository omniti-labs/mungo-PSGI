package Mungo::PSGI::Script;
# ABSTRACT: Mungo script file
use strict;
use warnings;
# VERSION
use Cwd ();
use Sub::Quote qw(quote_sub);

my %file_packages;
sub fetch {
    my $class = shift;
    my $file = Cwd::abs_path(shift);
    my $reload = shift;
    my $package = $file_packages{$file};
    if ($package && $package->can('new')) {
        my $script = $package->new;
        if ($reload && $script->file_timestamp > $script->timestamp) {
            $script->parse;
        }
    }
    else {
        return $class->generate($package, $file);
    }
}

my $package_inc = 0;
sub generate {
    my $class = shift;
    my $package = shift || sprintf __PACKAGE__ . '::__ASP_%s_', ++$package_inc;
    my $file = shift;
    no strict 'refs';

    my $self = bless {}, $package;
    *{ $package . '::new' } = sub { $self };
    @{ $package . '::ISA' } = __PACKAGE__;

    $self->parse($file);
    return $self;
}

sub parse {
    my $self = shift;
    if (@_) {
        $self->{file} = shift;
    }
    my $file = $self->{file};

    open $fh, '<', $file or die;
    my $contents = do { local $/; <$fh> };
    close $fh;
    $self->_clear_package;
    $self->_code_gen($contents);

    $self->timestamp($self->file_timestamp);
    return 1;
}

sub _clear_package {
    my $self = shift;
    my $package = ref $self;
    my $stash = Package::Stash->new($package);
    for my $symbol ($stash->list_all_symbols) {
        unless ($symbol eq '@ISA' || $symbol eq '&new') {
            $stash->remove_symbol($symbol);
        }
    }
}

sub code {
    my $self = shift;
    return $self->{code};
}

sub _code_gen {
    my $self = shift;
    my $content = shift;

    my $script_code = $self->_transform_code($content);
    my $package = ref $self;

    my $prolog = <<"END_CODE";
        package $package;
        my \$Request = \$script->{Request}
        my \$Server = \$Request->{Server}
        my \$Response = \$Request->{Response}
END_CODE
    my $code = quote_sub $package . '::code', $script_code, { '$script' => \$self }, { no_install => 1 };
    $self->{code} = $code;
}

sub _transform_code {
    my $self = shift;
    my $content = shift;
}

sub timestamp {
    my $self = shift;
    if (@_) {
        return $self->{timestamp} = shift;
    }
    return $self->{timestamp};
}

sub file_timestamp {
    my $self = shift;
    my $timestamp = (stat Cwd::abs_path($self->{file}))[9];
    return $timestamp;
}

sub run {
    my $self = shift;
    my $Request = shift;
}


1;

