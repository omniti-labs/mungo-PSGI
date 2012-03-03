use strict;
use warnings;
use Test::More;

use Plack::Builder;
use Mungo::PSGI;
use Plack::Test;
use File::Basename qw();
use File::Spec;
use HTTP::Request::Common;

my $tdata = File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'data');

my $app = Mungo::PSGI->new(root => $tdata);

test_psgi $app, sub {
     my $cb  = shift;
     my $res = $cb->(GET "/basic.asp");
     like $res->content, qr/passed mungo by extension/, "basic content output";

};

done_testing;
