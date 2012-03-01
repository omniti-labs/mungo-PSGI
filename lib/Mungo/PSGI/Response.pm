package Mungo::PSGI::Response;
# ABSTRACT: Mungo response object
use strict;
use warnings;
# VERSION
use parent qw(Plack::Response);
use Scalar::Util qw(weaken);
use URI;
use URI::QueryParam;

sub new {
    my $class = shift;
    my $req = shift;
    my $self = $class->SUPER::new;
    $self->{files} = [];
    $self->{Request} = $req;
    weaken $self->{Request};
    $self->body([]);
    return $self;
}

sub Request {
    my $self = shift;
    return $self->{Request};
}

sub CurrentFile {
    my $self = shift;
    my $files = $self->{files};
    return wantarray ? @$files : $files->[0];
}

sub AddHeader {
    my $self = shift;
    $self->header(@_);
}

sub Cookies {
    my $self = shift;
    my $cname = shift;
    my $value = shift;

    my $cookie = $self->cookies->{$cname} ||= {};
    if (!ref $cookie) {
        $cookie = $self->cookies->{$cname} = { value => $cookie }
    }

    if (! @_)
        $cookie->{value} = $value;
        return;
    }

    my $key = $value;
    my $value = shift;
    # cookie properties
    if ($key =~ /^(?:Expires|Path|Domain|Secure)$/) {
        $cookie->{lc $key} = $value;
        return;
    }
    # multivalue cookies
    my $oldvalue = $cookie->{value} || $self->{request}->Cookies;
    my $uri = URI->new;
    if (ref $oldvalue) {
        $uri->query_form($oldvalue);
    }
    else {
        $uri->query($oldvalue);
    }
    $uri->query_param($key, $value);
    $cookie->{value} = $uri->query;
}

sub Redirect {
    my $self = shift;
    $self->redirect(@_);
    $self->End;
}

sub Trapped {
    my $self = shift;
    @{ $self->{files} } > 1;
}

sub Include {
    my $self = shift;
    my $file = shift;
    my $script = Mungo::PSGI::Script->fetch($file, $self->{request}->env->{'mungo.reload'});
    $script->run($self->Request);
}

sub TrapInclude {
    my $self = shift;
    local $self->{body};
    $self->body([]);
    $self->Include(@_);
    my $body = $self->body;
    if ($body && ref $body && ref $body eq 'ARRAY') {
        $body = join '', @$body;
    }
    return $body;
}

sub print {
    my $self = shift;
    my $body = $self->body;
    push @$body, @_;
    return 1;
}

sub End {
    my $self = shift;
    die ["Mungo::End"];
}

sub Flush {
    my $self = shift;
    # XXX implement streaming output
}

# XXX implement i18n
sub i18nHandler {}
sub i18n {}

1;

