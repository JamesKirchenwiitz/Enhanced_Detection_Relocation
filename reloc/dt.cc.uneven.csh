#
#
#

set temp=$1
# set temp=`awk '{print $7}' matches.txt | sort -u`
if (! -e lags.$temp) mkdir lags.$temp
\mv *_tempcorr.txt *_lag.txt lags.$temp/.

echo -n "" >! phase.dat
foreach ev ( loc.$temp/eloc*loc )
   awk '{if (NF==14) $10=d" "$10; if (NR==1) {$NF=substr($NF,2); print $0;h=$5;m=$6;s=$7}else {t=(substr($6,9,2)-h)*3600+(substr($6,11,2)-m)*60+(substr($6,13)-s); printf "%-5s %16.3f %4.2f %s\n",$1,t,1,$10}}' $ev >> phase.dat
end

awk '/#/{print $NF}' phase.dat >! eve.id
wc -l eve.id
awk '{for (i=1;i<NR;i++) print $1,id[i]; id[NR]=$1}' eve.id >! cc.eve.id.pairs

saclst stlo stla stel kstnm f sac.$temp/*SAC | awk '{print $5,$3,$2,$4}' | sort -u >! station.dat

\cp cc.eve.id.pairs cc.all
echo -n "" >! cc.all.id
foreach stacha ( "`cat stacha.txt`" )
 set sta=`echo $stacha | awk '{print $1}'`
 set cha=`echo $stacha | awk '{print $2}'`

  if ( `\ls lags.$temp/*${sta}-${cha}_*.txt | wc -l` < 1 ) continue
  if ($cha == BHZ || $cha == EHZ || $cha == HHZ ) set pha=P
  if ($cha == BHE || $cha == EHN || $cha == HH1 || $cha == HH2 || $cha == HHN || $cha == HHE) set pha=S

# foreach sta ( `\ls lags.$temp/*HZ*lag*.txt | awk -F "_" '{split(substr($1,6),s,"-");print s[1]}'` )
  if ($sta == SKIP) continue
#  foreach cha ( HHZ HH1 )
#    if ($cha == BHZ || $cha == EHZ || $cha == HHZ) set pha=P 
#    if ($cha == BHE || $cha == EHN || $cha == HH1) set pha=S 
#    if ($sta == HIGH && $cha == BHZ) set cha=HHZ
#    if ($sta == HIGH && $cha == BHN) set cha=HHN
#    if ($sta == ODD && $cha == BHN) set cha=BH1
#    if ($sta == ODD && $cha == BHE) set cha=BH2
    set stan=$sta
    if ($sta == BC99) set stan=OHH3
    if ($sta == B983) set stan=OHH2
    if ($sta == 3y73) set stan=MUH1
    if ($sta == 3y86) set stan=MUG1
    if ($sta == 3y71) set stan=MUB1
    if ($sta == 3v62) set stan=EARS

  awk -F "/" '{print substr($NF,2,9)}' lags.$temp/$sta.$cha/file.exist.$temp >! lags.$temp/$sta.$cha/eve.id.$temp
  awk '{for (i=1;i<NR;i++) print $1,id[i]; id[NR]=$1}' lags.$temp/$sta.$cha/eve.id.$temp >! cc.$sta.$cha.eveid

    foreach typ ( lag tempcorr )
      echo $stan $cha $typ
      echo lags.$temp/*${sta}-${cha}_${typ}.txt cc.$sta.$cha.$typ s=$stan t=$typ p=$pha
      awk -F "," '{for (i=1;i<NR;i++) if (t=="lag") print s,$i; else {if ($i<.1) $i=0;print ($i),p}}' s=$stan t=$typ p=$pha lags.$temp/*${sta}-${cha}_${typ}.txt >! cc.$sta.$cha.$typ
      paste cc.all cc.$sta.$cha.$typ >! cc.temp
      \mv cc.temp cc.all
    end

   paste cc.$sta.$cha.eveid cc.$sta.$cha.lag cc.$sta.$cha.tempcorr >> cc.all.id

#  end
end

\rm cc*lag cc*tempcorr cc*eveid


sort cc.all.id | awk 'NF==6{if ($1!=o1||$2!=o2) print "#",$1,$2,0; print $3,$4,$5,$6;o1=$1;o2=$2}' | grep -v "NaN" >! dt.cc
