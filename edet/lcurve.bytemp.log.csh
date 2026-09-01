# 
#
#
set seqnum=$1 mad=1 cc1=.05 ## for 3 station
set temp=$seqnum:e wid=`echo 86400 3000 | awk '{print $1*$2}'`
set cha=9 # Number of channels required

set sta="3sta"

set files=( match/match.$seqnum.*$sta*2025* )

module load gmt
awk '$2>cc&&$2/$3>mad&&$4>=cha&&$2<=1' t=$temp w=$wid mad=$mad cc=$cc1 cha=$cha $files | sort -n | awk '{if ($1-o1>20&&NR>1) {print o0;o0=$0;o2=$2;if (sqrt(($1-$7)^2)<5)o2=1000} else if (o2<$2||sqrt(($1-$7)^2)<5) {o0=$0; o2=$2;if (sqrt(($1-$7)^2)<5)o2=1000} o1=$1}END{print o0}' | awk 'BEGIN{srand()}{$2+=rand()*.00001;print $1,$2}' >! lcurve.matches.$seqnum
if (`wc -l < lcurve.matches.$seqnum` < 10) then
  echo .99
  exit 
endif

sort -k 2 -n -r lcurve.matches.$seqnum >! lcurve.matches.sort.$seqnum
awk '{n++; print $2,log(n)/log(10)}' lcurve.matches.sort.$seqnum | tac | awk '{if (NR==1) s=$2; if ($2<.8*s) print}' > ! lcurve.cuml.log.all.$seqnum
awk -f ~/awk/runningslopeall.awk n=100 lcurve.cuml.log.all.$seqnum | awk 'NR>1 {print o0} {o0=$0}' >! lcurve.cuml.log.slope.$seqnum

awk '{print $1,$3,$2}' lcurve.cuml.log.slope.$seqnum | blockmean -R0/1/0/5 -I1/.02 | awk -f ~/awk/runningmean.awk n=10 | awk '{print $1,$3}' | awk -f ~/awk/runningslopeall.awk n=10 >! lcurve.cuml.log.acc.$seqnum 
set cc1=`awk '{if ($2>100) p=1;if ($2<-100&&p) exit;print}' lcurve.cuml.log.acc.$seqnum | awk -f ~/awk/maxline.awk c=2 | awk '{print $1}'`
tac lcurve.cuml.log.acc.$seqnum | awk 'NR>20' | tac | awk -f ~/awk/pick+peak+line.awk mu=20 | awk '$2<3000' >! lcurve.cuml.log.peaks.$seqnum
set mu=`awk -f ~/awk/max.awk c=2 lcurve.cuml.log.peaks.$seqnum | awk '{mu=100; if ($1<500) mu=$1/5;print mu}'`
set cc2=`tac lcurve.cuml.log.acc.$seqnum | awk 'NR>20' | tac | awk -f ~/awk/pick+peak+line.awk mu=$mu | tac | awk '{print $1;exit}'`
if ($cc2 == "") set cc2=`awk -f ~/awk/pick+peak+line.awk mu=$mu lcurve.cuml.log.acc.$seqnum | tac | awk '{print $1;exit}'`
if ($cc2 == "") set cc2=`awk -f ~/awk/pick+peak+line.awk mu=30 lcurve.cuml.log.acc.$seqnum | tac | awk '{print $1;exit}'`
set cc3=`awk '$1>cc2&&$2<20{print $1;exit}' cc2=$cc2 lcurve.cuml.log.acc.$seqnum`
if ($cc3 == "") set cc3=`awk '$1>cc2&&$2<40{print $1;exit}' cc2=$cc2 lcurve.cuml.log.acc.$seqnum`
if ($cc3 == "") set cc3=$cc2
if ($cc3 == "") set cc3=$cc1
if (`echo $cc1 $cc3 | awk '{if ($1>$2) print 1;else print 0}'`) set cc3=$cc1

 set m=`awk -f ~/awk/median.awk c=2 lcurve.cuml.log.slope.$seqnum`
 set sd=`awk -f ~/awk/stdev.awk c=2 m=$m lcurve.cuml.log.slope.$seqnum`
 set nsd=50
 set cc4=`awk -f ~/awk/runningmean.awk n=5 lcurve.cuml.log.slope.$seqnum | awk '$2>m+sd*n/10{print $1;exit}' m=$m sd=$sd n=$nsd`
 while (`echo $cc4 | wc -w` < 1 && $nsd > 20) 
  @ nsd --
  set cc4=`awk -f ~/awk/runningmean.awk n=5 lcurve.cuml.log.slope.$seqnum | awk '$2>m+sd*n/10{print $1;exit}' m=$m sd=$sd n=$nsd`
 end
 if (`echo $cc4 | wc -w` < 1) set cc4=$cc3
 if (`echo $cc4 | wc -w` < 1) set cc4=0.99
set cc=$cc4
 set cc=`echo "$cc1\n$cc2\n$cc3\n$cc4" | awk -f ~/awk/max.awk`

# Added this last one on Dec 18, 2024
set cc5=`awk '$1<cc4' cc4=$cc4 lcurve.cuml.log.all.$seqnum | trend1d -Fxm -N2 -V | & grep Poly | awk '{print -$5/$6}'`
set cc=$cc5  ## for 2 or 3 Station

if (`echo $* | grep -c cc` > 0) then
  echo $cc1 $cc2 $cc3 $cc4 $cc5 $nsd $cc $seqnum
else
  echo $cc
endif
# goto plot

# exit

plot:
if (`echo $* | grep -c plot` > 0) then
set max=`head -1 lcurve.cuml.log.all.$seqnum | awk '{print $2}'`
set tick=`echo 0 $max | awk -f ~/awk/tick.awk`
set psfile=lcurve.ps
awk '{print $1,10^$2}' lcurve.cuml.log.all.$seqnum >! lcurve.cuml.$seqnum
set max=`awk -f ~/awk/max.awk c=2 lcurve.cuml.$seqnum`
set cc0=0

if (`echo $* | grep -c wide` > 0) then
  gmtset LABEL_FONT_SIZE 20p ANNOT_FONT_SIZE_PRIMARY 14p LABEL_OFFSET 0.04i ANNOT_OFFSET_PRIMARY 0.04i
  echo 0 0 | psxy -R$cc0/1/1/$max -JX7/7l -W5 "-Ba.2f.1:Correlation Coefficient:/${tick}:Number of Matches:SWne" -X1 -K >! $psfile
else
  gmtset ANNOT_FONT_SIZE 10p LABEL_FONT_SIZE 12p LABEL_OFFSET 0.02i ANNOT_OFFSET_PRIMARY 0.02i
  echo 0 0 | psxy -R$cc0/1/1/$max -JX4.5/7l -W5 -Ba.2f.1/${tick}SWNe -X.7 -K >! $psfile
endif

awk '$1<cc4' cc4=$cc4 lcurve.cuml.log.all.$seqnum | trend1d -Fxm -N2 | awk '{print $1,10^$2}END{print c,1}' c=$cc5 | psxy -R -J -W15,orange -K -O >> $psfile
psxy lcurve.cuml.$seqnum -R -J -W5 -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc4 | psxy -R -J -Sc.15 -W5 -Gyellow -N -K -O >> $psfile

if (`echo $* | grep -c wide` < 1) then
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc | psxy -R -J -Sc.25 -W5 -N -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc1 | psxy -R -J -Sc.15 -W5 -Gblue -N -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc2 | psxy -R -J -Sc.15 -W5 -Ggreen -N -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc3 | psxy -R -J -Sc.15 -W5 -Gred -N -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc4 | psxy -R -J -Sc.15 -W5 -Gyellow -N -K -O >> $psfile
awk -f ~/awk/upsample.awk n=10 lcurve.cuml.$seqnum | awk '$1>=cc{print;exit}' cc=$cc5 | psxy -R -J -Sc.15 -W5 -Gorange -N -K -O >> $psfile

echo .05 2 16 0 0 LM $seqnum | pstext -R -J -O -K >> $psfile
echo .05 3 16 0 0 LM $cc | pstext -R -J -O -K >> $psfile
# psxy lcurve.norm -R.25/1/0/1 -JX7 -Ba.2f.1 >! $psfile
# psxy lcurve.rot -R-1/1/-1/1 -JX7 -Ba.2f.1 >! $psfile
# convert -density 200 $psfile $psfile:r.jpg

psxy lcurve.cuml.log.acc.$seqnum `minmax -I.1/10 lcurve.cuml.log.acc.$seqnum` -JX4.5/7 -Ba.1f.05/a50f10wSEN -K -O -X5 >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.25 -W5 -K -O >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc1 lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.15 -Gblue -W5 -K -O >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc3 lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.15 -Gred -W5 -K -O >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc2 lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.15 -Ggreen -W5 -K -O >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc4 lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.15 -Gyellow -W5 -K -O >> $psfile
awk '$1>=cc{print $1,$2;exit}' cc=$cc5 lcurve.cuml.log.acc.$seqnum | psxy -R -J -Sc.15 -Gorange -W5 -K -O >> $psfile
endif

echo 0 0 | psxy -R -J -O >> $psfile
gv $psfile
endif

if (`echo $* | grep -c keep` < 1) then
  \rm lcurve*.$seqnum
endif
