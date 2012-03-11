use strictures;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;
use Test::Fatal;


asp_like <<'END_ASP', <<'END_WANTED', 'no leader';
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

asp_like <<'END_ASP', <<'END_WANTED', 'interpolated trailer';
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

asp_like <<'END_ASP', <<'END_WANTED', 'no leader no trailer';
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

asp_like <<'END_ASP', <<'END_WANTED', 'literal trailer';
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

asp_like <<'END_ASP', <<'END_WANTED', 'printed trailer';
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

asp_like <<'END_ASP', <<'END_WANTED', 'printed trailer newline';
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

TODO: {
    local $TODO = 'Awaiting bugfix on trac ticket 17';
    asp_like <<'END_ASP', <<'END_WANTED', 'quoted start tag bug17';
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
}

like exception { run_asp <<'END_ASP' }, qr/@{[<<'END_ERROR']}/x, 'incomplete section';
Leader
<%
my $string = "string";
END_ASP
^
Can.t[ ]find[ ]end[ ]of[ ]ASP[ ]section
.*
line[ ]
END_ERROR

done_testing;
