use strictures 1;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;

use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Mungo::PSGI;

my $tdata = Mungo::Test->data;

my $app = Mungo::PSGI->new(root => $tdata);

test_psgi $app, sub {
    my $cb  = shift;
    foreach my $how (
        [ 'GET' ],
        [ 'POST', 'application/x-www-form-urlencoded' ],
        [ 'POST', 'multipart/form-data' ],
    ) {
        my ($method, $type) = @$how;
        for my $test (
            [ '' => {} ],
            [ 'foo=bar' => { foo => 'bar' } ],
            [ 'foo=' => { foo => '' } ],
            [ 'foo=1' => { foo => 1 } ],
            [ 'foo=I am the very model of a modern major general'
                => { foo => 'I am the very model of a modern major general' } ],
            [ 'foo=kittehs%20and%20ponies' => { foo => 'kittehs and ponies' } ],
            [ 'foo=1&bar=2' => { foo => 1, bar => 2 } ],
            [ 'foo=1&foo=2' => { foo => [1,2] } ],
        ) {
            my ($query, $expected) = @$test;

            my $url = 'dumper-query.asp?' . $query;
            my $req = HTTP::Request->new($method, "http://localhost/$url",
                $type ? ['Content-Type' => $type] : ());
            my $res = $cb->($req);

            is $res->code, 200, "${method}ing '$url' gives 200 status code";
            my $qs = eval $res->content;
            is $@, '', 'No error when evaling returned content';
            is_deeply $qs, $expected, "Result matches expected";
        }
    }
};


done_testing;
