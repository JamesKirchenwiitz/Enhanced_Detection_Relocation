#!/bin/csh
#
# Script to run the cross-correlation detection
#   Format for code below is:
#  cc.detect.yrs.netsta.py [template csv file] [yr1] [jd1] [yr2] [jd2] [net] [sta] [loc] [channels]
#

if (${#argv} < 1) then
  echo Specify the csv input file on the command line
  exit
endif

# Specify input file
# set incsv=$1 
# set num=$1:r:e
# set num=$1:r
set num=$1

module load anaconda-python3
source /software/python/anaconda3/etc/profile.d/conda.csh
module load gmt

if ( ! -e match ) mkdir match
if ( ! -e csv ) mkdir csv
if ( ! -e logs ) mkdir logs


# original getcatpy output
set incsv=getcatpy.$num.csv
set et=`echo 2020-01-01 | toepoch.csh`

awk -F "," 'NR>1{OFMT="%.6f";print ($1-et)/86400/365.25+2020,$3,$4,$6,$5,$1,"1970-01-01 00:00:00 getcatpy"}' et=$et $incsv >! $incsv:r.txt 

awk '{print $2,$3,$5}' $incsv:r.txt >! eq.loc
set eqloc=`awk -f ../dependencies/meanline.awk eq.loc | awk '{print $2"/"$1"/K"}'`

# Specifying station name
echo -n "" >! sta.loc
foreach sname (735B EF03 EF04)
  FetchMetadata -S $sname -s 2023-01-01 -e 2023-01-01 -C "HH?" | awk -F "|" 'NR>1{if (NR==2) printf "%s %s %s %s %s %s ",$6,$5,$2,$1,$3,$4;else printf "%s ",$4}END{print""}' >> sta.loc
end
awk 'BEGIN{print "sta,net,loc,cha1,cha2,cha3,lon,lat"}{OFS=",";print $3,$4,$5,$6,$7,$8,$1,$2}' sta.loc > ! sta.csv

## Calculate the closest station
set st=`mapproject -G$eqloc sta.loc | sort -k 4 -n | head -1`
## Use the next line to force a specific station
set st=`grep 735B sta.loc`
set sta=$st[3] staloc=$st[2],$st[1] net=$st[4] loc=$st[5] chas="$st[6] $st[7] $st[8]"
echo $sta $staloc $st
set stas=(735B EF03 EF04)

# old station configs
# set stas=(PB09 PB28 PB29)
# set stas=(PB28 PB29)

echo -n "" >! eq.times
foreach line ( "`cat eq.loc`" )
  set e=( $line )
  set eqloc=$e[1],$e[2]
  set eqdep=$e[3]
  set ttp=`wget "https://service.iris.edu/irisws/traveltime/1/query?evloc=[${eqloc}]&staloc=[${staloc}]&evdepth=${eqdep}&phases=ttp+&noheader=true&mintimeonly=true" -o tt.log -O - | awk '{if (NR==1) min=$c; if ($c<min) min=$c} END {print min}' c=4`
  set tts=`wget "https://service.iris.edu/irisws/traveltime/1/query?evloc=[${eqloc}]&staloc=[${staloc}]&evdepth=${eqdep}&phases=tts+&noheader=true&mintimeonly=true" -o tt.log -O - | awk '{if (NR==1) min=$c; if ($c<min) min=$c} END {print min}' c=4`
  echo $ttp $tts >> eq.times
end
paste $incsv:r.txt eq.times | awk 'BEGIN{print "epoch,decyear,lat,lon,dep,mag,ttp,tts"}{OFS=",";print $6,$1,$2,$3,$5,$4,$10,$11}' >! $num.csv
awk -F "," '{if (NR==1) h=$0; else print h"\n"$0 > "csv/"n"."$1".csv"}' n=$num $num.csv
awk -F "," 'NR>1{print $1,$4,$3,$5,$6}' $num.csv > ! $num.txt

### This is where the day range is set
# set window=7

#########
# setting for year timeframe
#########

# manually set timeframe
set yearday1="2018 160" 
set yearday2="2025 091"



#########
# previously set auto timeframe (buggy)
#########
#set yearday1=`awk -F "," 'NR>1{print $1}' $num.csv | /mnt/raya/bin/epoch2jda.csh | awk '{print $1,$2}' | sort | head -n 1`
#set yearday2=`awk -F "," 'NR>1{print $1}' $num.csv | /mnt/raya/bin/epoch2jda.csh | awk '{print $1,$2}' | sort | tail -n 1`


### This is where we submit the jobs to the scheduler
foreach csv ( csv/$num*csv )
#  sbatch -t 1440 --partition=serial_onecore --output=logs/slurm-%j.out cc.detect.yrs.netsta.mad.py $csv $yearday1 $yearday2 $num $net $sta $loc $chas
  sbatch -t 2880 --partition=serial_onecore --output=logs/slurm-%j.out cc.detect.yrs.3sta.mad.local.py $csv $yearday1 $yearday2 $num $stas
end

# sleep 60
