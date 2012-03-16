use strictures 1;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;
use Test::Fatal;

asp_like <<'END_ASP', { status => 200, output => <<'END_WANTED' }, 'Page with text before End()';
mungo-success
<%
   $Response->End();
%>
END_ASP
^mungo-success$
END_WANTED

asp_like <<'END_ASP', { status => 200, output => <<'END_WANTED' }, 'Page with text after End()';
mungo-success
<%
   $Response->End();
%>
mungo-failure
END_ASP
^mungo-success$
END_WANTED

asp_like <<'END_ASP', { status => 200, output => <<'END_WANTED' }, 'End() inside loop';
mungo-success
<%
  for (1 .. 10) {
    %><%= $_ %><%
  $Response->End() if($_ >= 6);
}
%>
<%
  for (1 .. 10) {
    %><%= $_ %><%
  $Response->End() if($_ >= 6);
}
%>
END_ASP
^mungo-success\n123456$
END_WANTED

asp_like <<'END_ASP', { status => 200, output => <<'END_WANTED', headers => [ 'X-mungo-test-header' => 'ponies' ] }, 'Page with headers prior to End';
<%
   $Response->AddHeader('X-mungo-test-header' => 'ponies');
%>
mungo-success
<%
   $Response->End();
%>
END_ASP
^
\nmungo-success\n
$
END_WANTED

done_testing;
