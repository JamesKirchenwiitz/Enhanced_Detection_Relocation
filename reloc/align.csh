#
#
#

set temp=$1
set nr=`awk '{if ($1==$7) print NR}' matches.$temp.txt`

foreach stacha ( "`cat stacha.txt`" )
 set sta=`echo $stacha | awk '{print $1}'`
 set cha=`echo $stacha | awk '{print $2}'`
  if ($cha == HHZ) set t="a"
  if ($cha == HH1 || $cha == HH2 || $cha == HHN || $cha == HHE) set t="t0" 
  set c2=`awk '$1==s&&$2!=c{print $2}' s=$sta c=$cha stacha.txt`
  awk -F "," '{for (i=1;i<=NF;i++) s[i]+=$i;n++}END{for (i=1;i<=NF;i++) print s[i]/n}' lags.$temp/${sta}-${cha}_lag.txt >! align.lag
  saclst $t f sac.$temp/*$sta*$cha* >! align.$sta.$cha.$t.init
  paste align.$sta.$cha.$t.init align.lag | awk '{print "r",$1"\nch",t,$2+$3"\nwh"}' t="$t" >! align.m
  echo "q" >> align.m
  sac align.m
  replace align.m $cha $c2
  echo -n "" >! align.cha2.m
  foreach sacfile (`awk '/SAC/{print $2}' align.m`)
    if (-e $sacfile) then
      awk '{if ($1=="r") {if ($2==s) p=1; else p=0;} if (p) print}' s=$sacfile align.m >> align.cha2.m
    endif
  end
  sac align.cha2.m
end
