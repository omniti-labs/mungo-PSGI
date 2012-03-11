use strictures;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;
use Test::Fatal;


asp_like <<'END_ASP', <<'END_WANTED', 'hash outside block';
#<% my $stuff = "mungo-output" %>
<%= $stuff %>
END_ASP
^
\#\n           #
mungo-output   # no whitespace
$
END_WANTED


asp_like <<'END_ASP', <<'END_WANTED', 'hash starts block';
<%#
   my $stuff = "mungo-output"; 
%><%= $stuff %>
END_ASP
^
mungo-output   # no whitespace
$
END_WANTED


asp_like <<'END_ASP', <<'END_WANTED', 'hash throughout block';
<% my $stuff = "mungo-output" %>
<%
  # print "Ponies!";
  # $stuff = "should-not-see-this"; 
%><%= $stuff %>
END_ASP
^
\n           #
mungo-output   # no whitespace
$
END_WANTED

TODO: {
    local $TODO = 'awaiting fix for trac17';

    asp_like <<'END_ASP', <<'END_WANTED', 'hash-inside-equals-block';
<%=# "should-not-see-this" %>
END_ASP
^
$
END_WANTED

}


asp_like <<'END_ASP', <<'END_WANTED', 'html comment';
<!-- html-comment -->
<% my $stuff = 'mungo-output' %><%= $stuff %>
END_ASP
^
<!--\shtml-comment\s-->\n           #
mungo-output\n   # no whitespace
$
END_WANTED


asp_like <<'END_ASP', <<'END_WANTED', 'pod entire block';
<% my $stuff = 'mungo-output' %>

<%

=for should-be-ignored

$stuff = 'should-not-be-seen';

=cut

%>

<%= $stuff %>
END_ASP
^
\n+
mungo-output   # no whitespace
$
END_WANTED

done_testing;
