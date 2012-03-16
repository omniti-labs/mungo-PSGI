package Mungo::PSGI;
# ABSTRACT: Apache::ASP inspired lightweight framework for PSGI
use strictures 1;
# VERSION
use parent qw(Plack::App::File);
use Plack::Util::Accessor qw(buffer reload globals);

use Plack::Request;
use File::Spec;
use Mungo::PSGI::Request;
use Try::Tiny;
use File::Basename ();

sub serve_path {
    my ($self, $env, $file) = @_;
    $env->{'mungo.reload'} = $self->reload;
    $env->{'mungo.root'} = $self->root;
    $env->{'mungo.use_globals'} = $self->globals;
    $env->{'mungo.file_base'} = File::Spec->rel2abs(File::Basename::dirname($file));
    my $request = Mungo::PSGI::Request->new($env);
    try {
        $request->Response->Include($file);
    }
    catch {
        local $SIG{__DIE__};
        unless ($_ && ref $_ && ref $_ eq 'ARRAY' && $_->[0] eq 'Mungo::End') {
            die $_;
        }
    };
    return $request->Response->finalize;
}
sub to_app {
    my $self = shift;
    my $app = $self->SUPER::to_app(@_);
    if ($ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development') {
        require Plack::Middleware::StackTrace::Mungo;
        $app = Plack::Middleware::StackTrace::Mungo->wrap($app);
    }
    return $app;
}

1;

=head1 SYNOPSIS

    use Mungo::PSGI;
    
    my $app = Mungo::PSGI->(root => $root);

=head1 DESCRIPTION

Mungo::ASP is designed to be compatible with ASP scripts written for Mungo.

=cut

