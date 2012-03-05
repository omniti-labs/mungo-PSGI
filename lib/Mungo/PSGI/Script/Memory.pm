package Mungo::PSGI::Script::Memory;
# ABSTRACT: Mungo script from memory
use strict;
use warnings;
# VERSION
use parent qw(Mungo::PSGI::Script);
use Digest::MD5 ();

sub new {
    my $class = shift;
    my $content = shift;
    my $name = shift || '(ANON)';
    my $self = $class->SUPER::new(
        content => $content,
        name => $name,
    );
    return $self;
}

my %cache;
sub fetch {
    my $class = shift;
    my ($content) = @_;
    my $ident = Digest::MD5::md5_base64($content);
    if ($cache{$ident}) {
        return $cache{$ident};
    }
    my $script = $cache{$ident} = $class->new(@_);
    return $script;
}

sub file { $_[0]->{name} }
sub content { $_[0]->{content} }


1;

