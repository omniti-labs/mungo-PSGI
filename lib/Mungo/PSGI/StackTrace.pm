package Mungo::PSGI::StackTrace;
# ABSTRACT: Stacktrace including Mungo code only
use strictures 1;
# VERSION
use Try::Tiny;
use parent qw(Devel::StackTrace);

BEGIN {
    if (try { require Devel::StackTrace::WithLexicals; Devel::StackTrace::WithLexicals->VERSION(0.08); 1 }) {
        our @ISA = qw(Devel::StackTrace::WithLexicals);

        *_make_frames = sub {
            my $self = shift;

            my $filter = $self->_make_frame_filter;

            my $raw = delete $self->{raw};
            for my $r ( @{$raw} ) {
                next unless $filter->($r);

                $self->_add_frame( $r );
            }
        }
    }
}

sub new {
    my $class = shift;
    my %opts = @_;
    my $ignore = $opts{ignore_package};
    $ignore = [ $ignore ]
        unless ref $ignore;

    push @$ignore,
        'Mungo::PSGI::Response',
        keys %Carp::Internal,
        __PACKAGE__,
    ;
    $opts{ignore_package} = $ignore;

    my $done;
    $opts{frame_filter} = sub {
        my $frame = shift;
        $frame->{caller}[3] =~ s/^Mungo::PSGI::Script::__ASP_\d+__::__ANON__$//;
        if ($frame->{caller}[0] eq 'Mungo::PSGI') {
            $done = 1;
        }
        return ! $done;
    };

    return $class->SUPER::new(%opts);
}

sub _record_caller_data {
    my $self = shift;
    $self->SUPER::_record_caller_data();

    my @shifted = ('') x 11;
    my $shift_args = [];
    for my $frame ( reverse @{ $self->{raw} }) {
        for my $i (3..10) {
            my $new = $frame->{caller}[$i];
            $frame->{caller}[$i] = $shifted[$i];
            $shifted[$i] = $new;
        }
        my $new = $frame->{args};
        $frame->{args} = $shift_args;
        $shift_args = $new;
    }
}

1;

