#
# Script to use log based lcruve to get the best matches for a template
#

chdir ..
set temp=$1 
set clust=$2
set cc=`lcurve.bytemp.log.csh $clust.$temp 3sta 9`

set combine=$clust.combine.bytemp.txt

awk '$1>1577836800&&$7==t&&$2>=cc' cc=$cc t=$temp $combine >! proc/matches.$temp.txt

