#
# Sciprt to obtain SAC files to create lag and corr files for hypodd from a set of SAC files
#  SAC file are assumed to have a filename starting with a 3 digit number
#  File 001 should have precise P and S picks on all stations and channels
#  User needs to specify the station names and channel types

set temp=$1
set name=`grep -h $temp ../events.*.usgs.name.txt | awk '$1==t{print $2;exit}' t=$temp`
echo $temp $name

wf.ms.sac.csh $temp



awk -F '[<>\"]' '{if (substr($2,1,4)=="pick") p="";if (/value/) t=$3;if (/netw/) {for(i=1;i<=NF;i++) if (index($i,"netw")>0) n=$(i+1)}if (/loca/) {for(i=1;i<=NF;i++) if (index($i,"loca")>0) l=$(i+1)} if (/stat/) {for(i=1;i<=NF;i++) if (index($i,"stat")>0) s=$(i+1)} if (/chan/&&index(t,"T")) {for(i=1;i<=NF;i++) if (index($i,"chan")>0) c=$(i+1)} if (/Hint/) {p=$3;if (p=="P") c=substr(c,1,2)"Z"} if (substr($2,2,4)=="pick") {print t,n,s,l,c,p}}' ../quakeml/quakeml.$name.xml | uniq > ! picks.all.txt

echo -n "" >! picks.txt
echo -n "" >! picks.taup.txt
echo -n "" >! temp.files
foreach stacha ( "`cat stacha.txt`" )
 set sta=`echo $stacha | awk '{print $1}'`
 set cha=`echo $stacha | awk '{print $2}'`
 set evlo=`awk -F "," '$1==t{print $3,$4;exit}' t=$temp ../getcatpy.*.csv`
 set evdp=`awk -F "," '$1==t{print $6;exit}' t=$temp ../getcatpy.*.csv`
 set stlo=`awk '$4==s{print $2,$1;exit}' s=$sta station.loc`
 if ($cha == HHZ ) set ch2=HH
 if ($cha == HH1 ) set ch2=HH2
 if ($cha == HH2 ) set ch2=HH1
 if ($cha == HHN ) set ch2=HHE
 if ($cha == HHE ) set ch2=HHN
 set ph=t0 pha=S phlist=s,S
 if ($cha == HHZ) set ph=a pha=P phlist=p,P,Pn,Pg
 set phtime=`taup_time -h $evdp -ph $phlist -evt $evlo -sta $stlo -time`
 echo $sta $cha $ph $phtime >> picks.taup.txt
   if (`grep $sta picks.all.txt | grep -c $cha` < 1) then
     echo "ERROR - no pick in xml file on $sta $cha for this template $temp"
     if (`grep $sta picks.all.txt | grep -c $ch2` > 0 ) then
       echo "SOLVED - found pick in xml file on $sta $ch2 for this template $temp"
       awk '$3==s&&$5==c' s=$sta c=$ch2 picks.all.txt | grep $ch2 | awk '{sub(c2,c1);print}' c1=$cha c2=$ch2 >> picks.txt
     else
       set pick=`saclst $ph f sac.$temp/$temp*.$sta.$cha.SAC | awk 'NR==1{print $2}'`
       if ( $pick == -12345 ) then
         echo "ERROR - no pick in SAC file on $sta $cha for this template $temp"
       else
         echo "SOLVED - found pick in SAC file on $sta $cha for this template $temp"
         set ep0=`saclst kzdate kztime f sac.$temp/$temp*.$sta.$cha.SAC | awk 'NR==1{print $2,$3}' | toepoch.dec.csh`
         set dt=`echo $ep0 $pick | awk '{printf "%.2f",$1+$2}' | fromepoch.csh | awk '{sub("Z","T");print substr($1,1,26)"Z"}'`
         saclst KNETWK KSTNM KHOLE KCMPNM f sac.$temp/$temp*.$sta.$cha.SAC | awk '{$1=dt;print $0,p}' dt=$dt p=$pha >> picks.txt
       endif
     endif
   else 
     grep $sta picks.all.txt | grep $cha >> picks.txt
   endif

### New to check and make sure all seismograms are available for the template event
  if (-e sac.$temp/$temp.$sta.$cha.SAC) then
    echo sac.$temp/$temp.$sta.$cha.SAC >> temp.files
  else
### If missing seismograms then this is how to find next best option
   foreach ep ( `sort -k 2 -n -r matches.$temp.txt | awk '{print $1}'` )
    if (-e sac.$temp/$ep.$sta.$cha.SAC) then
     echo sac.$temp/$ep.$sta.$cha.SAC >> temp.files
     break
    endif
   end
  endif

end
sort -u picks.txt >! picks.uniq
\mv picks.uniq picks.txt

awk '{print $1}' picks.txt | toepoch.dec.csh | paste - picks.txt >! picks.ep.txt
set ep0=`saclst kzdate kztime f sac.$temp/$temp*HHZ.SAC | awk 'NR==1{print $2,$3}' | toepoch.dec.csh`
awk '{print e,t,$0}' e=$ep0 t=$temp picks.ep.txt | awk '{if (/HZ/) {p="a";k="P"} else {p="t0";k="S"} print "r sac."temp"/*."$6"."$8".SAC\nch "p,$3-$1,"k"p,k"\nwh"}END{print "q"}' temp=$temp >! sac.temp.m
sac sac.temp.m

## Be careful to interpolate delta if stations have different sampling rates
saclst delta a t0 f sac.$temp/*SAC >! file.dps
set dm=`awk -f ~/awk/min.awk c=2 file.dps`
awk '$2>dm{print "r",$1"\ninterpolate delta",dm"\nw over"}END{print "q"}' dm=$dm file.dps >! interpolate.m
sac interpolate.m


set sacfiles=`cat temp.files`
echo "r $sacfiles\nqdp off" >! sac.pick.m
#awk '$1==t{print "ch evlo",$2,"evla",$3"\nsort gcarc\nppk\nsc echo run wh and then q"}' t=$temp ../karnescluster?.txt >> sac.pick.m
# Replacing ../karnescluster?.txt with 599.txt due to id mismatch
awk '$1==t{print "ch evlo",$2,"evla",$3"\nsort gcarc\nppk\nsc echo run wh and then q"}' t=$temp ../599.txt >> sac.pick.m
sac sac.pick.m

saclst kstnm kcmpnm a t0 f $sacfiles | awk '{p="t0";n="S";c=5;if (/HHZ/) {p="a";n="P";c=4} print "r sac."t"/*"$2"*"$3"*.SAC\nch",p,$c,"k"p,n"\nwh"}END{print "q"}' t=$temp > ! sac.pickall.m
sac sac.pickall.m

saclst delta a t0 ka kt0 f sac.$temp/*SAC >! file.taup.dps

exit
echo -n "" >! sac.taup.m
foreach line ("`cat picks.taup.txt`")
  set l=($line)
  grep $l[1] file.dps | grep $l[2] | awk '{if (ph=="a"&&($3<0||$3>1e4)) print "r",$1"\nch",ph,pt+5,"k"ph,"P\nwh";if (ph=="t0"&&($4<0||$4>1e4)) print "r",$1"\nch",ph,pt+5,"k"ph,"S\nwh"}' ph=$l[3] pt=$l[4] >> sac.taup.m
end
echo "q" >> sac.taup.m
sac sac.taup.m
saclst delta a t0 ka kt0 f sac.$temp/*SAC >! file.taup.dps
