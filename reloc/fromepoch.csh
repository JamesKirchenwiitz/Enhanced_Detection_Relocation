#!/bin/csh -f
#
#

while ( 1 )
  set LINE = "$<"
  if ( "$LINE" == "" ) then
    break
  endif
  
  date -u -d "1970-01-01 + $LINE sec" "+%Y-%m-%dZ%H:%M:%S.%N" 
  
end
