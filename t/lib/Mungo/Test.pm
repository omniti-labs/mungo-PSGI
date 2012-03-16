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
    $script->run($req);
    my $output = join '', @{ $req->Response->body };
    return $output;
}

sub asp_like {
    my $asp = shift;
    my $like = shift;
    my $Test = $CLASS->builder;
    my @params = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    try {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $output = run_asp($asp, @params);
        $Test->like($output, qr/$like/x, @params);
    }
    catch {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $Test->ok(0, @params);
        $Test->diag($_);
    };
}

1;

