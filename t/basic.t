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

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->(GET "/basic.asp");
    like $res->content, qr/passed mungo by extension/, "basic content output";

};

done_testing;
