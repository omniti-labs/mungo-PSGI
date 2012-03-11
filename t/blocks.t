use strictures;
use File::Spec;
use File::Basename ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use Test::More;
use Mungo::Test;
use Test::Fatal;

my $cond_pattern = qr{
    ^
    \n
    mungo-success\n
    \n
    $
}x;

my $loop_pattern = qr{
    ^
    \n*1\n*2\n*3\n*4\n*5\n*6\n*7\n*8\n*9\n+
    mungo-success
    $
}x;

asp_like <<'END_ASP', $cond_pattern, 'bare block';
<% { %>
mungo-success
<% } %>
END_ASP

asp_like <<'END_ASP', $cond_pattern, 'if';
<% if (1) { %>
mungo-success
<% } %>
END_ASP

asp_like <<'END_ASP', $cond_pattern, 'if else';
<% if (0) { %>
mungo-failure - 0 is true?
<% } else { %>
mungo-success
<% } %>
END_ASP

asp_like <<'END_ASP', $cond_pattern, 'if elsif else';
<% if (0) { %>
mungo-failure - 0 is true?
<% } elsif(1) { %>
mungo-success
<% } else { %>
mungo-failure - 1 is false?
<% } %>
END_ASP

asp_like <<'END_ASP', $cond_pattern, 'unless';
<% unless (0) { %>
mungo-success
<% } %>
END_ASP

asp_like <<'END_ASP', $loop_pattern, 'for';
<% for (1..9) { %><%= $_ %><% } %>
mungo-success
END_ASP

asp_like <<'END_ASP', $loop_pattern, 'for next';
<% 
  LOOP:
   for (-2..9) { %>
<% if ($_ < 1) { next LOOP; } %>
<%= $_ %>
<% } %>
mungo-success
END_ASP

asp_like <<'END_ASP', $loop_pattern, 'for last';
<% 
  LOOP:
   for (1..20) { %>
<% if ($_ > 9) { last LOOP; } %>
<%= $_ %>
<% } %>
mungo-success
END_ASP

asp_like <<'END_ASP', $loop_pattern, 'while';
<% 
  my $x = 0;
  while ($x < 9) {
    $x++;
%>
<%= $x %>
<% } %>
mungo-success
END_ASP

done_testing;
