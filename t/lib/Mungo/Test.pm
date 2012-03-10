package Mungo::Test;
use strict;
use warnings;
use parent qw(Test::Builder::Module);
use Try::Tiny;
use Test::MockObject;
use Mungo::PSGI::Request;
use Mungo::PSGI::Script::Memory;

our @EXPORT = qw(run_asp asp_like);
my $CLASS = __PACKAGE__;

sub run_asp {
    my $asp = shift;
    my $req = Mungo::PSGI::Request->new({});
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
