package Mungo::PSGI::Script::File;
# ABSTRACT: Mungo script from file
use strict;
use warnings;
# VERSION
use parent qw(Mungo::PSGI::Script);

sub new {
    my $class = shift;
    my $file = shift;
    my $self = $class->SUPER::new(file => $file);
    return $self;
}

my %cache;
sub fetch {
    my $class = shift;
    my ($file, $reload) = @_;
    my $script = $cache{$file};
    if (! $script || $reload && ! $script->up_to_date) {
        return $cache{$file} = $class->new(@_);
    }
    return $script;
}

sub file { $_[0]->{file} }

sub file_timestamp {
    my $self = shift;
    my $timestamp = (stat Cwd::abs_path($self->file))[9];
    return $timestamp;
}

sub up_to_date {
    my $self = shift;
    return $self->timestamp > $self->file_timestamp;
}

sub content {
    my $self = shift;
    my $file = $self->file;
    open my $fh, '<', $file or die "Can't read $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

1;

