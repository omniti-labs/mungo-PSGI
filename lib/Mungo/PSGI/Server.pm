package Mungo::PSGI::Server;
# ABSTRACT: Mungo server object
use strictures 1;
# VERSION
use Mungo::PSGI::Request;
use URI::Escape ();
use HTML::Entities ();
use Scalar::Util qw(weaken);

sub new {
    my ($class, $req) = @_;
    my $self = bless {
        Request => $req,
    }, $class;
    weaken $self->{Request};

    return $self;
}

sub Request {
    my $self = shift;
    return $self->{Request};
}
sub Response {
    my $self = shift;
    return $self->Request->Response;
}

sub CurrentFile {
    my $self = shift;
    return $self->Response->CurrentFile;
}

sub HTMLEncode { shift; HTML::Entities::encode_entities(@_); }
sub HTMLDecode { shift; HTML::Entities::decode_entities(@_); }
sub URLEncode { shift; URI::Escape::uri_escape(@_); }
sub URLDecode { shift; URI::Escape::uri_unescape(@_); }

1;

