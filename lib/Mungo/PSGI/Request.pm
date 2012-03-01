package Mungo::PSGI::Request;
# ABSTRACT: Mungo request object
use strict;
use warnings;
# VERSION
use parent qw(Plack::Request);

sub new {
    my ($class, $env, $file) = @_;
    my $self = $class->SUPER::new($env);
    $self->{mungo_server} = Mungo::PSGI::Server->new($self);
    $self->{mungo_response} = Mungo::PSGI::Response->new($self);
    return $self;
}

sub Response {
    my $self = shift;
    return $self->{mungo_response};
}

sub Server {
    my $self = shift;
    return $self->{mungo_response};
}

sub Cookies {
    my ($self, $cookie, $key) = shift;
    my $cookie = $self->cookies->{$cookies};
    if ($cookie !~ /[=&]/) {
        return $cookie;
    }
    my $uri = URI->new;
    $uri->query($cookie);
    my %inner = $uri->query_form;
    if (defined $key) {
        return $inner{$key};
    }
    return \%inner;
}

sub QueryString {
    my $self = shift;
    my $params = $self->query_parameters;
    if (@_) {
        return $params->get(shift);
    }
    my $copy = $params->as_hashref;
    return wantarray ? %$copy : $copy;
}

sub Form {
    my $self = shift;
    my $params = $self->body_parameters;
    if (@_) {
        return $params->get(shift);
    }
    my $copy = $params->as_hashref;
    return wantarray ? %$copy : $copy;
}

sub Params {
    my $self = shift;
    my $params = $self->parameters;
    if (@_) {
        return $params->get(shift);
    }
    my $copy = $params->as_hashref;
    return wantarray ? %$copy : $copy;
}

sub ServerVariables {
    my $self = shift;
    my $var = shift;
    if ($var eq 'REFERER' || $var eq 'REFERRER') {
        return $self->referer;
    }
    elsif ($var eq 'DOCUMENT_ROOT') {
        # XXX return something reasonable
        return '/';
    }
    elsif ($var eq 'HTTP_HOST') {
        return $self->uri->host;
    }
    elsif ($var eq 'REMOTE_IP') {
        return $self->address;
    }
    return undef;
}

sub IsSecure {
    my $self = shift;
    return $self->secure;
}

sub Header {
    my $self = shift;
    return $sefl->header(@_);
}

1;

