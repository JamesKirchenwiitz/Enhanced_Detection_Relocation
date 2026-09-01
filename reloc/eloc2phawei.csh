#
#
#

set temp=$1
foreach ep ( `awk '{print $1}' matches.$temp.txt` )
 elocate.sac.align.csh $ep:r $temp
end
