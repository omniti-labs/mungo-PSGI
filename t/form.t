use strictures;
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

sub to_expected {
    my %out;
    my %mult;
    while (@_) {
        my ($key, $value) = (shift, shift);
        if (!exists $out{$key}) {
            $out{$key} = $value;
        }
        elsif ($mult{$key}) {
            push @{ $out{$key} }, $value;
        }
        else {
            $mult{$key}++;
            $out{$key} = [ $out{$key}, $value ];
        }
    }
    return \%out;
}

test_psgi $app, sub {
    my $cb  = shift;
    foreach my $type ('application/x-www-form-urlencoded', 'multipart/form-data' ) {
        for my $test (
            [ 'empty' ],
            [ 'string',         foo => 'bar' ],
            [ 'empty string',   foo => '' ],
            [ 'integer',        foo => 1 ],
            [ 'unescaped',      foo => 'I am the very model of a modern major general' ],
            [ 'escaped',        foo => 'kittehs%20and%20ponies' ],
            [ 'two',            foo => '1', bar => '2' ],
            [ 'repeated',       foo => 1, foo => 2 ],
        ) {
            my ($name, @content) = @$test;
            my $req = POST 'http://localhost/dumper-form.asp',
                'Content-Type' => $type,
                'Content' => \@content,
            ;
            my $res = $cb->($req);
            my $expected = to_expected(@content);

            is $res->code, 200, "$name form via $type gives 200 status code";
            my $qs = eval $res->content;
            is $@, '', 'No error when evaling returned content';
            is_deeply $qs, $expected, "Result matches expected";
        }
    }
};


done_testing;


