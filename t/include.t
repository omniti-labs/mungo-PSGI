use strictures;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;
use Test::Fatal;

my $success = qr{
    ^
    \n
    mungo-success\n
    \n
    $
}x;

asp_like <<'END_ASP', $success, 'include relative';

<%
   $Response->Include('success.inc');
%>
END_ASP

asp_like <<'END_ASP', $success, 'include string';

<%
   # Workaround for quoted start tag bug
   # http://labs.omniti.com/trac/mungo/ticket/17
   my $mhtml = '<' . '%= "mungo-success\n" %' . '>';
   $Response->Include(\$mhtml);
%>
END_ASP

asp_like <<'END_ASP', $success, 'include pass args';
<%
   $Response->Include('args.inc', 'mungo-success');
%>
END_ASP

asp_like <<'END_ASP', $success, 'trap include';
<%
   my $caught = $Response->TrapInclude('success.inc');
%>
<%= $caught %>
END_ASP

done_testing;
