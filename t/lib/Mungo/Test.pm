package Mungo::Test;
use strictures 1;
use parent qw(Test::Builder::Module);
use Try::Tiny;
use Test::MockObject;
use Mungo::PSGI::Request;
use Mungo::PSGI::Script::Memory;
use File::Spec::Functions qw(updir catdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Data::Dumper ();

our @EXPORT = qw(run_asp asp_like);
my $CLASS = __PACKAGE__;

my $data = abs_path(catdir(dirname(__FILE__), updir, updir, 'data'));

sub data {
    $data;
}

sub run_asp {
    my $asp = shift;
    my $req = Mungo::PSGI::Request->new({
        'mungo.file_base' => $data,
    });
    $req->Response->body([]);
    my $script = Mungo::PSGI::Script::Memory->new($asp, @_);
    try {
        $script->run($req);
    }
    catch {
        local $SIG{__DIE__};
        unless ($_ && ref $_ && ref $_ eq 'ARRAY' && $_->[0] eq 'Mungo::End') {
            die $_;
        }
    };
    my $output = join '', @{ $req->Response->body };
    return wantarray ? ($output, $req->Response) : $output;
}

sub _dump {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    my $plain = Data::Dumper::Dumper(shift);
    chomp $plain;
    return $plain;
}

sub asp_like {
    my $asp = shift;
    my $like = shift;
    my $Test = $CLASS->builder;
    my $name = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    try {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my ($output, $resp) = run_asp($asp, $name);
        if (ref $like) {
            $like->{status}
                and $Test->is_num($resp->code, $like->{status}, "$name status");
            if ($like->{headers}) {
                my $nok = '';
                my @headers = @{ $like->{headers} };
                while (@headers) {
                    my ($name, $value) = (shift @headers, shift @headers);
                    my $got = _dump($resp->header($name));
                    $value = _dump($value);
                    if ($got ne $value) {
                        $nok .= "expected $value, got $got for header $name\n";
                    }
                }
                $Test->ok( ! $nok, "$name headers")
                    or $Test->diag($nok);
            }
            $like = $like->{output};
        }
        if ($like) {
            $Test->like($output, qr/$like/x, "$name output");
        }
    }
    catch {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $err = $_;
        if (ref $like) {
            if ($like->{error}) {
                $Test->like($err, qr/$like->{error}/x, "$name error");
            }
            else {
                $Test->ok(0, "$name $_")
                    for sort keys %$like;
                $Test->diag($err);
            }
        }
        else {
            $Test->ok(0, "$name output");
            $Test->diag($err);
        }
    };
}

1;

