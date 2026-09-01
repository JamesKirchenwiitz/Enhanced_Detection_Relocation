#!/bin/csh
#
# Sciprt to create lag and corr files for hypodd from a set of SAC files
#  SAC files should be in a directory named sac
#  File 001 should have precise P and S picks on all stations and channels
#  User needs to specify the station names and channel types

module load gcc-12.2.0
# set num=001
# \cp matches.combine.$num.txt matches.txt
set num=$1

set sta=$2
set cha=$3
   if ( $cha == HHZ ) set cp=a cn=0 tbefore=0.5 tafter=1.0
   if ($cha == HH1 || $cha == HH2 || $cha == HHN || $cha == HHE) set cp=t0 cn=1 tbefore=0.5 tafter=1.5
#  if ( $cha == HHZ ) set cp=a cn=0 tbefore=2.0 tafter=3.0
#  if ($cha == HH1 || $cha == HH2 || $cha == HHN || $cha == HHE) set cp=t0 cn=1 tbefore=2.0 tafter=3.0
  echo $sta $cha 

  chdir lags.$num
  if (! -e $sta.$cha) mkdir $sta.$cha
  chdir $sta.$cha

  echo -n "" >! ../${sta}-${cha}_tempcorr.txt
  echo -n "" >! ../${sta}-${cha}_lag.txt
  awk '{printf "../../sac.%s/%s.%s.%s.SAC ",$7,$1,s,c}' s=$sta c=$cha ../../matches.$num.txt >! file.list.$num
  echo -n "" >! file.exist.$num
  foreach f ( `cat file.list.$num` )
    if (`ls -lt $f |& awk '{print $5*1}'` > 1) echo $f >> file.exist.$num
  end
  set f=( `cat file.exist.$num` )
  set n=`echo $f | wc -w`
  echo $n
  @ a = 1
  while ($a <= $n)
    @ b = 1 
    while ($b <= $n)

      if (`\ls -l $f[$b] $f[$a] | awk '{if ($5==0) n=1}END{print n}' n=0`) then
        set cc=( 0 0 )
      else
        if (`saclst e f $f[$b] $f[$a] | awk '{if (NR==1) o=$2; else {if (sqrt((o-$2)^2)>10) print 1; else print 0}}'`) then
          set cc=( 0 0 )
        else

         set delta=`saclst delta f $f[$b] | awk '{print $2}'`
         set cc=(`cor2sac4 1 $f[$b] $f[$a] $cn $tbefore $tafter 0.25 1 | awk '{print $1,$2*d}' d=$delta`)
#         set timdiff=`saclst $cp f $f[$b] $f[$a] | awk '{if (NR==1) t=$2; else print t-$2}'`

        endif
      endif
      if ($b != 1) then
        echo -n "," >> ../${sta}-${cha}_tempcorr.txt
        echo -n "," >> ../${sta}-${cha}_lag.txt
      endif
      echo -n $cc[1] >> ../${sta}-${cha}_tempcorr.txt
      echo -n $cc[2] >> ../${sta}-${cha}_lag.txt
#      echo -n $timdiff >> ../${sta}-${cha}_lag.txt
      @ b ++
    end
    echo "" >> ../${sta}-${cha}_tempcorr.txt
    echo "" >> ../${sta}-${cha}_lag.txt
    @ a ++
  end
