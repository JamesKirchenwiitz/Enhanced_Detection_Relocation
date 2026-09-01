#!/bin/csh -f
# 
# Script to run all of the hypodd scripts
#

   

### Run these as of 1/10/2026 ###
## Templates identified by their epoch time, example templates below
# >M4: 1738207596 (M4.7); 1694717439 (M4.1)
# >M3: 1738295946 (3.5); 1735942489 (3.1); 1713312658 (3.2); 1694476161 (3.1); 1694462841 (3.0); 1587216815 (3.1)



# set temp=1694978267 combine=../karnescluster2.combine.bytemp.txt
# awk '$7==t' t=$temp $combine >! matches.$temp.txt
## \cp matches.$temp.txt matches.txt
set temp=$1



echo Starting Runme on template $temp
# for redoing matches
#echo duplicating temp
#temp.duplicator.csh $temp
#echo done


echo $temp | fromepoch.csh

# builds input file from edet
get.matches.csh $temp soutx # Let's use this command instead to focus on the best matches

wc -l matches.$temp.txt

# pulls waveform data
get.sac.csh $temp # you can skip this if sac files exist already


echo Check waveforms
#plot.wf.mag.match.temp.chas.ws.csh $temp EF04

# waveform cross-correlation
echo starting wfcorr.multi.csh $temp
wfcorr.multi.csh $temp # you can skip this if tempcor and lag files exist already

align.csh $temp # you can skip this if tempcor and lag files exist already

echo Check waveforms again to see if they are more aligned
#plot.wf.mag.match.temp.chas.ws.csh $temp EF04


# don't need if temp has perfect lag files
echo starting wfcorr.multi.csh $temp
wfcorr.multi.csh $temp # we should run it again after the seismograms have been aligned

# absolute location
echo starting eloc2phawei.csh $temp
\rm -r loc.$temp
eloc2phawei.csh $temp

# hypodd input:
dt.cc.uneven.csh $temp 

# relative relocation
hypodd.csh $temp 
#\rm hypodd.loc.$temp

# map view plot
mapx.hypodd.csh $temp
