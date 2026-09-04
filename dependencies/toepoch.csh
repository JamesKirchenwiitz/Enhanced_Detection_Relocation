#!/bin/csh -f
#
#

while ( 1 )
  set LINE = "$<"
  if ( "$LINE" == "" ) then
    break
  endif
  
  date -u -d "$LINE" +%s

end

