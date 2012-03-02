package Plack::Middleware::Mungo;
# ABSTRACT: Middleware to enable Mungo
use strict;
use warnings;
# VERSION
use parent qw(Plack::Middleware);
use Mungo::PSGI;

use Plack::Util::Accessor qw( path root buffer pass_through );

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_mungo($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_mungo {
    my ($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    $self->{mungo} ||= Mungo::PSGI->new({
        root => $self->root,
        reload => $self->reload,
        buffer => $self->buffer,
    });
    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{mungo}->call($env);
}

1;
