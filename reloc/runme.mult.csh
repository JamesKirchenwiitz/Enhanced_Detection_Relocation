#!/bin/csh -f
# 
# Script to run all of the hypodd scripts on the multitemplate version
#

### Edit the multi.temp.list file to specify the chronological number and the template epoch times

# Running template number 1599295729
#set mult=1599295729


set mult=$1


########################q
# edit below
########################
### This script will create the combined match file from the templates you choose in multi.temp.list
echo staring multi.temp.csh $mult
multi.temp.csh $mult

### Change this depending on which combination of templates you want to run
\cp matches.combine.$mult.txt matches.multi.txt
\mv matches.combine.$mult.txt matches.$mult.txt


# We do not run get.sac.csh because the sac files should exist already
# can skip wfcorr and eloc if files exist for the multi-template combination already
# echo Starting wfcorr.multi.multi.csh $mult
# wfcorr.multi.multi.csh $mult 


echo Starting eloc2phawei.mult.csh $mult
\rm -r loc.$mult
eloc2phawei.multi.csh $mult

# set mult=601
echo Starting dt.cc.mult.csh
# dt.cc.uneven.multi.csh $mult
dt.cc.picks.csh $mult

echo Starting hypodd.csh
hypodd.csh $mult

echo Starting mapx.hypodd.multi.abs.csh
mapx.hypodd.multi.abs.csh $mult

echo Starting mapx.hypodd.mult.csh
mapx.hypodd.multi.abs.tempnum.csh $mult

echo Starting mapx.hypodd.multi.abs.tn.coupe.csh
mapx.hypodd.multi.abs.tn.coupe.csh $mult

echo starting map.hypodd.multi.wide.csh
map.hypodd.multi.wide.csh $mult

#echo starting wf plot
#mult.plot.wf.mag.allsta.csh $mult
