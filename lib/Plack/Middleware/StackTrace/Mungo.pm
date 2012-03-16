package Plack::Middleware::StackTrace::Mungo;
# ABSTRACT: Displays Mungo stack trace on errors
use strictures 1;
# VERSION
use parent qw(Plack::Middleware::StackTrace);
use Mungo::PSGI::StackTrace;

sub call {
    my $self = shift;
    local $Plack::Middleware::StackTrace::StackTraceClass = 'Mungo::PSGI::StackTrace';
    return $self->SUPER::call(@_);
}

1;
