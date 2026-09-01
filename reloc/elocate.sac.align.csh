#!/bin/csh
#
# Simple script to run elocate on picks from SAC files
#   SAC filenames with picks should be listed on the command line
#   P and S wave arrivals should be stored in "A" and "T0" header variables
#
# Script provided by Mike Brudzinski - brudzimr@muohio.edu
# sac2eloc and elocate are from Computer Programs in Seismology written by Robert Herrmann - http://www.eas.slu.edu/People/RHHErrmann/CPS/CPS33.html
# 

if (${#argv} < 1) then
  echo "usage: elocate.csh [SAC file names]"
  echo "  example: elcoate.csh `\ls *.HHZ`"
  exit
endif

set temp=$2

goto start
if (! -e sac2eloc) then
  echo "\n sac2eloc program does not exist or is inaccessible."
  wget "http://moodle.glg.muohio.edu/mikeb/code/sac2eloc"
endif

echo -n "" >! sacloc.m
foreach f ( $* )
  set sta=$f:r:r:e cha=$f:r:e
  /home/mikeb/bin/FetchMetadata -S $sta -C $cha | & awk -F "|" 'NR>4{print "r",f"\nch stla",$5,"stlo",$6,"stel",$7"\nw over";exit}' f=$f >> sacloc.m
end
echo q >> sacloc.m
sac sacloc.m

start:
module load gcc-12.2.0
sac2eloc sac.$temp/$1.*.HHZ.SAC
awk '$11=="P"' elocate.dat >! elocate.align
sac2eloc sac.$temp/$1.*.HH{N,1}.SAC
awk '$11=="S"' elocate.dat >> elocate.align
\mv elocate.align elocate.dat
echo $1

set lat=`awk '{sum+=$c;n++}END{print sum/n}' c=15 elocate.dat`
set lon=`awk '{sum+=$c;n++}END{print sum/n}' c=16 elocate.dat`
set dep=10

if (! -e VEL.MOD || `wc -l < VEL.MOD` < 2) then
  \rm VEL.MOD
  echo "VEL.MOD file does not exist."
  echo "Retrieving it from a webpage..."
  wget "http://moodle.glg.muohio.edu/mikeb/code/VEL.MOD"
endif
set model=7
set model=3
#set model=4


echo -n "" >! elocate.dep
@ ddep = 10
while ($ddep < 100)
  set dep=`echo $ddep | awk '{print $1/10+.01}'`
  elocate -LAT $lat -LON $lon -DEPTH -$dep -BATCH -M $model >! elocate.out
  if (`grep -c Depth elocate.out`) then
    echo -n "$dep " >>! elocate.dep
    awk '{if (/RMS/) {t=$4;n++}if (/Latitude/) y=$7; if (/Longitude/) x=$7;if (/Depth/) z=$5}END{if (n<1) print ""; else print x*100,y*10,z,t*100,x*100+y*10+z+t*100}' elocate.out >>! elocate.dep
  endif
  @ ddep ++
end
set dep=`awk -f ~/awk/minline.awk c=6 elocate.dep | awk '{print $1}'`
set dep=`awk '{if (NR>1&&$1>2.4&&$1<3.4) print $0,sqrt(($6-o6)^2);o6=$6}' elocate.dep | awk -f ~/awk/minline.awk c=7 | awk '{print $1}'`


if (! -e loc.$temp) mkdir loc.$temp

elocate -LAT $lat -LON $lon -DEPTH -$dep -BATCH -M $model | tee elocate.out | awk '{if (/Lat/) {la=$3;lae=$5;} if (/RMS/) e=$4; if (/Long/) {lo=$3;loe=$5} if (/Dep/) de=$5; if (/Epoch/) ep=int($4); if(/Event Time/) ev=$4}END{print "#",substr(ev,1,4),substr(ev,5,2),substr(ev,7,2),substr(ev,9,2),substr(ev,11,2),substr(ev,13),la,lo,d,e,loe,lae,de,epi}' d=$dep epi=$1:r | tee loc.$temp/elocate.$1.loc

grep -a eX elocate.out | tee -a loc.$temp/elocate.$1.loc
