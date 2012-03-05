use strict;
use warnings;
use Test::More;

use Mungo::PSGI::Script::Memory;
use Mungo::PSGI::Request;
use Test::MockObject;
use Try::Tiny;

my @tests = (

{ name => 'no-leader', asp => <<'END_ASP', wanted => <<'END_WANTED' },
    Leader
    <%
    for (1 .. 100) {
    %><%= $_ %><%
    }
    %>
END_ASP
    ^
    Leader\n      # newline in file => newline in output
    12345\d+100   # no whitespace
    $
END_WANTED

{ name => 'interpolated-trailer', asp => <<'END_ASP', wanted => <<'END_WANTED' },
    Leader
    <%
    for (1 .. 100) {
    %><%= $_ %><%
    }
    %><%= "Trailer" %>
END_ASP
    ^
    Leader\n
    12345\d+100   # no whitespace
    Trailer       # no whitespace
    $
END_WANTED

{ name => 'no-leader-no-trailer', asp => <<'END_ASP', wanted => <<'END_WANTED' },
<%
for (1 .. 100) {
  %><%= $_ %><%
}
%>
END_ASP
    ^
    12345\d+100   # no whitespace
    $
END_WANTED

{ name => 'literal-trailer', asp => <<'END_ASP', wanted => <<'END_WANTED' },
    <%
    for (1 .. 100) {
    %><%= $_ %><%
    }
    %>
    Trailer
END_ASP
    ^
    12345\d+100\n
    Trailer
    $
END_WANTED

{ name => 'printed-trailer', asp => <<'END_ASP', wanted => <<'END_WANTED' },
    Leader
    <%
    for (1 .. 100) {
    %><%= $_ %><%
    }
    %><% print "Trailer" %>
END_ASP
    ^
    Leader\n
    12345\d+100   # no whitespace
    Trailer       # no whitespace
    $
END_WANTED

{ name => 'printed-trailer-newline', asp => <<'END_ASP', wanted => <<'END_WANTED' },
    Leader
    <%
    for (1 .. 100) {
    %><%= $_ %><%
    }
    %><% print "Trailer" %>
END_ASP
    ^
    Leader\n
    12345\d+100   # no whitespace
    Trailer\n       # literal newline in print
    $
END_WANTED

{ name => 'quoted-start-tag-bug17', todo => "Awaiting bugfix on trac ticket 17",
    asp => <<'END_ASP', wanted => <<'END_WANTED' },
    <%
    my $string = '<%= "string" %>';
    %>
    mungo-success
END_ASP
    ^
    \n
    mungo-success\n
    \n
END_WANTED

);

plan tests => scalar @tests;

my $req = Mungo::PSGI::Request->new({});
my $resp = $req->Response;

for my $test (@tests) {
    TODO: {
        local $TODO = $test->{todo}
            if $test->{todo};

        my $asp = $test->{asp};
        $asp =~ s/^    //msg;
        my $wanted = qr/$test->{wanted}/x;
        my $name = "$test->{name} script";

        $req->Response->body([]);
        try {
            my $script = Mungo::PSGI::Script::Memory->new($asp, $test->{name});
            $script->run($req);
            my $output = join '', @{ $resp->body };

            like $output, $wanted, $name;
        }
        catch {
            fail $name;
            diag $_;
        }
    }
}

