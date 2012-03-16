package Mungo::PSGI::Request;
# ABSTRACT: Mungo request object
use strictures 1;
# VERSION
use parent qw(Plack::Request);
use Mungo::PSGI::Server;
use Mungo::PSGI::Response;

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
    return $self->{mungo_server};
}

sub Cookies {
    my ($self, $cname, $key) = shift;
    my $cookie = $self->cookies->{$cname};
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
    my $params = $self->query_parameters->as_hashref_mixed;
    if (@_) {
        return $params->{ +shift };
    }
    return wantarray ? %$params : $params;
}

sub Form {
    my $self = shift;
    my $params = $self->body_parameters->as_hashref_mixed;
    if (@_) {
        return $params->{ +shift };
    }
    return wantarray ? %$params : $params;
}

sub Params {
    my $self = shift;
    my $params = $self->parameters->as_hashref_mixed;
    if (@_) {
        return $params->{ +shift };
    }
    return wantarray ? %$params : $params;
}

sub ServerVariables {
    my $self = shift;
    my $var = shift;
    if ($var eq 'REFERER' || $var eq 'REFERRER') {
        return $self->referer;
    }
    elsif ($var eq 'DOCUMENT_ROOT') {
        return $self->env->{'mungo.root'};
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
    return $self->header(@_);
}

sub use_globals {
    my $self = shift;
    return $self->env->{'mungo.use_globals'};
}

1;

