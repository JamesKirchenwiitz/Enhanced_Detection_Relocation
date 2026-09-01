#
#
#
#set seqnum=277 mad=25
# set seqnum=$1 mad=15 cc=.30
set seqnum=$1 mad=1 cc=.30

# if (! -e $seqnum.txt ) then
  awk -F "," '$1*1>1{print $1,$4,$3,$5,$6}' $seqnum.csv >! $seqnum.txt
# endif

# fix.mad.csh $seqnum
# set mad=35 # MAD threshold
set cha=9 # Number of channels required

set sta="3sta"
# set sta=HUIG
# set sta=PNIG

# foreach badtemp ( `cat bad.temps`)
#  if (`\ls match/match.$badtemp* | wc -l`) then
#    \mv match/match.$badtemp* bad-temps
#  endif
# end

echo -n "" >! combine.bytemp.all
if (! -e combine.bytemp.cc.$seqnum) then
 echo -n "" >! combine.bytemp.cc.$seqnum
 foreach temp (`\ls match/match.$seqnum.??????????.$sta* | awk -F "." '{for (i=2;i<=NF-6;i++) printf "%s.",$i;print $(NF-5) }' | sort -u`)

  set file=( match/match.$temp.*$sta* )
  set cc=`lcurve.bytemp.log.csh $temp`

  if ( `cat $file | wc -l` < 2 ) then
   set cc=0.9
  endif
  echo $cc $file

  awk '$2>cc&&$2/$3>mad&&$4>=cha&&$6<10' mad=$mad cc=$cc cha=$cha $file >! combine.bytemp.temp
  set nm=`wc -l < combine.bytemp.temp`
  cat combine.bytemp.temp >> combine.bytemp.all
  echo $temp $cc $nm | tee -a combine.bytemp.cc.$seqnum
end

else
 foreach temp (`\ls match/match.$seqnum.??????????.$sta* | awk -F "." '{for (i=2;i<=NF-6;i++) printf "%s.",$i;print $(NF-5) }' | sort -u`)
  set cc=`awk '$1==t{print $2}' t=$temp combine.bytemp.cc.$seqnum | tail -1`
  if ($cc == 0) then
    set cc=`lcurve.3sta.csh $temp`
    if ( `cat $file | wc -l` < 2 ) then
     set cc=0.9
    endif
    echo $temp $cc | tee -a combine.bytemp.cc.$seqnum
  endif
  set file=( match/match.$temp.*$sta* )
  awk '$2>cc&&$2/$3>mad&&$4>=cha&&$6<10' mad=$mad cc=$cc cha=$cha $file >> combine.bytemp.all
 end
endif


sort -n combine.bytemp.all >! combine.bytemp.sort
awk '{if ($1-o1>20&&NR>1) {print o0;o0=$0;o2=$2;if (sqrt(($1-$7)^2)<20)o2=1000} else if (o2<$2||sqrt(($1-$7)^2)<20) {o0=$0; o2=$2;if (sqrt(($1-$7)^2)<20)o2=1000} o1=$1}END{print o0}' combine.bytemp.sort >! $seqnum.combine.bytemp.txt

cat $seqnum.txt $seqnum.combine.bytemp.txt | awk '{if (NF==5) loc[$1]=$2" "$3" "$4" "$5; else print $0,loc[$7]}' >! $seqnum.combine.bytemp.loc.txt

awk '{print $1}' $seqnum.combine.bytemp.txt | fromepoch.T.csh | paste - $seqnum.combine.bytemp.loc.txt >! $seqnum.combine.bytemp.loc.date.txt

echo "date-time epoch-time cc mad #sta mag amp-ratio template-id temp-lon temp-lat temp-depth temp-mag decimal-year day-of-year" >! $seqnum.combine.bytemp.loc.date.dy.txt
set mine=`echo 2023-01-01 | toepoch.csh` my=2023
awk '{OFMT="%.6f";dy=($2-mine)/86400/365.25+my; print $0,dy,int((dy-my)*365.25)+1}' my=$my mine=$mine $seqnum.combine.bytemp.loc.date.txt >> $seqnum.combine.bytemp.loc.date.dy.txt

awk '{OFS=","; print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14}' $seqnum.combine.bytemp.loc.date.dy.txt >! $seqnum.combine.bytemp.loc.date.dy.csv
awk -F "," 'BEGIN{srand()}{OFS=",";OFMT="%.4f";if (NR>1) {$9+=(rand()-.5)/100;$10+=(rand()-.5)/100} print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14}' $seqnum.combine.bytemp.loc.date.dy.csv > ! $seqnum.combine.bytemp.wig.date.dy.csv

exit
awk '{print $9,$3,$4,$6}' $seqnum.combine.bytemp.date.dy.txt >! sequences/seq.match.$seqnum

echo -n "" >! $seqnum.combine.bytemp.full.cat
echo -n "" >! $seqnum.combine.bytemp.nocat.txt
foreach line ( "`cat $seqnum.combine.bytemp.date.dy.txt`" )
  set l=( $line )
  set loc=( `awk '$6==e{print $3,$2}' e=$l[8] sequences/seq.full.$seqnum` )  
  
  awk '($6-e)^2<50&&($3-x)^2<1&&($2-y)^2<1{print $0,cc}' x=$loc[1] y=$loc[2] e=$l[2] cc=$l[3] full.2010-2022_09_01.cat >! match.out

  if (`wc -l < match.out` > 0 && `echo $l[3] | awk '{if ($1<1) print 1; else print 0}'`) then
    cat match.out >>! $seqnum.combine.bytemp.full.cat
  else
    echo $line >>! $seqnum.combine.bytemp.nocat.txt
  endif
end
