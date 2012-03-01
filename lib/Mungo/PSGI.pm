package Mungo::PSGI;
# ABSTRACT: Apache::ASP workalike for PSGI
use strict;
use warnings;
# VERSION
use parent qw(Plack::App::File);
use Plack::Util::Accessor qw(buffer reload);

use Plack::Request;
use File::Spec;

sub serve_path {
    my ($self, $env, $file) = @_;
    $env->{'mungo.reload'} = 1
        if $self->reload;
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

