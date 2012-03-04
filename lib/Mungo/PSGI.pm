package Mungo::PSGI;
# ABSTRACT: Apache::ASP workalike for PSGI
use strict;
use warnings;
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
        unless ($_ && ref $_ && ref $_ eq 'ARRAY' && $_->[0] eq 'Mungo::End') {
            die $_;
        }
    };
    return $request->Response->finalize;
}

1;

__END__

=head1 SYNOPSIS

    use Plack::Builder;
    builder {
        enable_if { $_[0]->{SCRIPT_NAME} =~ /\.asp$/ } "Mungo::PSGI";
        $app;
    };

=cut

