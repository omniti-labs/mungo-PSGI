<%
   use Data::Dumper ();
   my $qs = $Request->QueryString;
   local $Data::Dumper::Terse = 1;
   $Response->print( Data::Dumper::Dumper($qs) );
%>
