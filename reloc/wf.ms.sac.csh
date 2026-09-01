#
# Script to get SAC waveforms using WebServices Timeseries
#

set e1=-5 e2=40
set temp=$1
if (-e sac.$temp) \rm -r sac.$temp
mkdir sac.$temp
foreach stacha ( "`cat stacha.txt`" )
 set sta=`echo $stacha | awk '{print $1}'`
 set cha=`echo $stacha | awk '{print $2}'`
 set req=`echo $stacha | awk '{print $3}'`
    foreach ep ( `awk '{print $1}' matches.$temp.txt` )
      set t1=`date -u -d "1970-01-01 + $ep sec +$e1 sec" "+%Y-%m-%dT%H:%M:%S.%N" | awk '{print substr($1,1,22)}'`
echo t1=$t1

  set stal=`echo $sta | awk '{print tolower($1)}'`
  set chal=`echo $cha | awk '{print tolower($1)}'`

  set tl=`echo $e1 $e2 | awk '{print $2-$1}'`
  set yj=`date -u -d "1970-01-01 + $ep sec" "+%Y.%j"`
  set yr=`date -u -d "1970-01-01 + $ep sec" "+%Y"`

  /mnt/raya/encap/gipptools-2015.225/bin/mseedcut --output-dir=$cwd --trace-start=$t1 --trace-length=$tl ../data/$sta/$yr/$sta*$cha*$yj
  if (`\ls ${stal}*.$chal | wc -l` < 1) then
    echo "${stal}.$chal was not created"
    continue
  endif
  /mnt/raya/encap/tracedsp-0.9.8/tracedsp -od $cwd -o sac.$temp/$ep.$sta.$cha.SAC -RM -HP 5/4 -TAP 0.02 ${stal}*.$chal
  \rm ${stal}*.$chal

    end
    wget "http://${req}/fdsnws/station/1/query?level=channel&station=${sta}&cha=${cha}&format=text" -O - | awk -F "|" 'NR==2{print "r sac."temp"/*."$2"."$4".SAC\nch stla "$5" stlo "$6" stel "$7*1" stdp "$8*1" cmpaz "$9*1" cmpinc "$10*1"\nwh\nq"}' temp=$temp >! sac.chst.m
   if ( `\ls sac.$temp/*.$sta.$cha.SAC | wc -l` ) then
    sac sac.chst.m
   endif

  echo saclst b e f sac.$temp/$ep.$sta.$cha.SAC
  if ( `saclst b e f sac.$temp/$ep.$sta.$cha.SAC | awk '{print int($3-$2)}'` < 10 ) \rm sac.$temp/$ep.$sta.$cha.SAC

end
