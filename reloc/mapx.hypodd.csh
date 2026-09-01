#
#
#

module load gmt
set temp=$1
# set temp=`awk '{print $7}' matches.txt | sort -u`
set psfile=mapx.hypodd.$temp.ps
gmtset BASEMAP_TYPE plain D_FORMAT %lg PLOT_DEGREE_FORMAT D ANNOT_FONT_SIZE 8p LABEL_FONT_SIZE 10p LABEL_OFFSET 0.01i ANNOT_OFFSET_PRIMARY 0.01i ANNOT_OFFSET_SECONDARY 0.01i
set xlshift=0 ylshift=0

### Mike added these calculations to identify the RMS error of the relocations 
set rms=`awk '{print $22+$23}' hypoDD.reloc | awk -f ~/awk/mean.awk`
set sd=`awk '{print $22+$23}' hypoDD.reloc | awk -f ~/awk/stdev.awk m=$rms`



### The script now limit the plots to only those within 1 standard deviation of the mean RMS value
awk '$22+$23<m+sd' m=$rms sd=$sd hypoDD.reloc | sort | awk '{if (NR==1) b=$1;m=$12+($11-2011)*12-1;la=$2;lo=$3;os="";n=4;o=8;print lo,la,m,n,o,$1,($1-b)/86400}' >! hypodd.loc.$temp

set c=1
set xm=`awk -f ~/awk/median.awk c=$c hypodd.loc.$temp`
set xsd=`awk -f ~/awk/stdev.awk m=$xm c=$c hypodd.loc.$temp`
set c=2
set ym=`awk -f ~/awk/median.awk c=$c hypodd.loc.$temp`
set ysd=`awk -f ~/awk/stdev.awk m=$ym c=$c hypodd.loc.$temp`
set range=`echo $xm $xsd $ym $ysd | awk '{print "-R"$1-$2*4"/"$1+$2*10"/"$3-$4*7"/"$3+$4*7}'`
echo $range
set range=`minmax -I.01 hypodd.loc.$temp`
# set range=`minmax -I.1 hypodd.loc.$temp`
awk '{print $1,$2}' hypodd.loc.$temp >! map.xy
# awk '{print $4,$3}' event.dat >> map.xy
set range=`minmax -I.01 map.xy`

# echo 0 0 | psxy $range -JM3 -X.5  -P -K >! $psfile
# awk '{if (/#/) {print lo,la,m,n,o,"1"$NF substr($7,2); n=0;o=0;m=$3+($2-2011)*12-1;la=$8;lo=$9;os=""}else if ($3>0.3&&$1!="ERPA"){o++; if ($1!=os) {n++;if ($1=="YSUO") n+=0}os=$1}}' phase.dat >! elocate.ytown.loc.nsta
set xtick=`echo $xm $xsd | awk '{print $1-$2*4,$1+$2*10}' | awk -f ~/awk/tick.awk`
set ytick=`echo $ym $ysd | awk '{print $1-$2*4,$1+$2*10}' | awk -f ~/awk/tick.awk`

set xsize=5
# set ysize=`minmax -I.01 hypodd.loc.$temp -C | awk '{print x/cos(($3+$4)/2*3.14/180)*($4-$3)/($2-$1)}' x=$xsize`
set ysize=`minmax -I.01 map.xy -C | awk '{print x/cos(($3+$4)/2*3.14/180)*($4-$3)/($2-$1)}' x=$xsize`
echo $ysize
if (`echo $ysize | awk '{if ($1>7.5) print 1;else print 0}'`) then
  set xsize=`echo 5 7.5 $ysize | awk '{print $2/$3*$1}'`
  set ysize=7.5
endif
echo x=$xsize y=$ysize
set xshift=`echo $xsize 0.5 | awk '{print $1+.5}'`
set yshift=`echo $ysize 0.5 | awk '{print $1+.5}'`

set ed=`awk '{e=$7}END{print e}' hypodd.loc.$temp`
set inc=`echo 0 $ed | awk -f ~/awk/inc.awk`
makecpt -T0/$ed/$inc >! color.cpt
# goto inset

echo 0 0 | psxy $range -JM$xsize  -B$xtick/$ytick -K -P -X.5 >! $psfile
pscoast -R -J -Dh -N1 -N2/2,white -G190 -K -O -Ba1f.5 >> $psfile

# echo -81.205 39.422 | psxy -R -J -Sa.15 -O -K >> $psfile
# echo "-81.19 39.409 12 0 0 6 Sept-4" | pstext -R -J -K -O >> $psfile

# psxy ../faults/faults.gmt -R -J -M -W1 -K -O >> $psfile

# echo 0 0 | psxy -R-80.72/-80.64/41.10/41.13 -JM2  -Ba.02f.01wyesNE -K -O -X5 -Y3 >> $psfile
awk 'NF>3&&$5>4&&$4>2{print $1,$2,$7}'  hypodd.loc.$temp | psxy -R -J -Sc.09 -Ccolor.cpt -W0.0005,black -K -O >> $psfile
# awk 'NF>3&&$5>4&&$4>2{print $1,$2,$6}'  hypodd.loc.$temp | psxy -R -J -Sc.05 -Gred -W0.0005,black -K -O >> $psfile
# awk 'NF>3&&$4>3&&$5>4{print $1,$2,$3,$4*$4/200}' elocate.ytown.loc.nsta | psxy -R -J -Sc -Ctime.cpt -K -O >> $psfile

awk '{print $4,$3}' event.dat | psxy -R -J -Sx.1 -K -O >> $psfile
# psscale -D5.9/0.3/1.5/.1h -B6:"Month of 2011": -A -Ctime.cpt -K -O >> $psfile
# echo "-80.6926 41.1182 3 265 72 12 4.0 -80.71 41.125" | psmeca -C1to -V -Sa.27 -R -J -K -O >> $psfile

#set og=/home/mikeb/rob/oilgas/Utica_080616.csv
#awk -F "," 'NR>6&&$8*1>0&&$10*1>0&&substr($5,1,5)=="Drill"{print">\n" $9,$8"\n"$11,$10}' $og | tee wells.drill.gmt | psxy -W2,yellow -M -R -J -K -O >> $psfile

# psxy ../catalog/iris.ohio.1980+ ../catalog/ohioseis.gmt -Sx.15 -R -J -K -O -W3 >> $psfile 
# awk '/WASH/{print -$8,$7}' ../catalog/ohioseis.txt | psxy -Sx.15 -R -J -K -O -W3 >> $psfile 
# awk '/WASH/{if ($1<2012) print -$8,$7-.003,10,0,0,"CT",$2"/"$3"/"$1-2000; else print -$8-.004,$7,10,0,0,"RM",$2"/"$3"/"$1-2000}' ../catalog/ohioseis.txt | pstext -R -J -K -O >> $psfile 

#psxy /duos/temp-match/ohio/rob/drill/monroe.maria/*txt -W2,black -M -R -J -K -O >> $psfile


awk '$22+$23<m+sd' m=$rms sd=$sd hypoDD.reloc | awk '{if (NR==1) b=$1; print $4,$2,($1-b)/86400}' >! hypodd.xyt
awk '{print $1,$2}' hypodd.xyt >! map.xy
# awk '{print $5,$3}' event.dat >> map.xy
set range=`minmax -I.01 map.xy`
# set ysize=`minmax -I.01 hypodd.loc.$temp -C | awk '{print 5/cos(($3+$4)/2*3.14/180)}'`
set ztick=`minmax -I.01 map.xy -C | awk '{print $1,$2}' | awk -f ~/awk/tick.awk`

echo 0 0 | psxy $range -JX2/$ysize -X$xshift -K -O >> $psfile
minmax -I.01 map.xy -C | awk -f ~/awk/box.awk | psxy -R -J -G190 -K -O -B${ztick}:Depth:/${ytick}ESnw >> $psfile
awk '{print $5,$3}' event.dat | psxy -R -J -Sx.1 -K -O >> $psfile
psxy hypodd.xyt -R -J -Sc.09 -Ccolor.cpt -W0.0005,black -K -O >> $psfile
echo 0 0 | psxy -R -J -X-$xshift -K -O >> $psfile

awk '$22+$23<m+sd' m=$rms sd=$sd hypoDD.reloc | awk '{if (NR==1) b=$1; print $3,$4,($1-b)/86400}' >! hypodd.xyt
set range=`minmax -I.01 hypodd.xyt`

echo 0 0 | psxy $range -JX$xsize/2 -Y$yshift -K -O >> $psfile
minmax -I.01 hypodd.xyt -C | awk -f ~/awk/box.awk | psxy -R -J -G190 -K -O -B$xtick/${ztick}:Depth:WsNe >> $psfile
awk '{print $4,$5}' event.dat | psxy -R -J -Sx.1 -K -O >> $psfile
psxy hypodd.xyt -R -J -Sc.09 -Ccolor.cpt -W0.0005,black -K -O >> $psfile
echo 0 0 | psxy -R -J -Y-$yshift -K -O >> $psfile

set tick=`echo 0 $ed | awk -f ~/awk/tick.awk`
psscale -D6.5/$yshift/1.5/.1h "-B${tick}:Time (days):" -A -Ccolor.cpt -K -O >> $psfile


echo 0 0 | psxy -R -J -O >> $psfile
gv $psfile
convert -density 200 -rotate 90 $psfile $psfile:r.jpg
# convert -rotate 90 $psfile $psfile:r.pdf

exit

set orient=""
img2grd /home/mikeb/database/topo/topo_11.1.img  -R$lon1/$lon2/$lat1/$lat2 -T1  -D -m1 -V -Gtopo.grd >&! topo.img.out
  set toposcale=/home/mikeb/database/scale/topo.midwest.cpt
  set toposcale=/home/mikeb/database/scale/topo.ohio.cpt
  grdimage topo.grd -C$toposcale -JM -K -O $orient >> $psfile
  psbasemap -J -Ba5f1 -R -K -O $orient >> $psfile
  pscoast -Di -N1 -N2 -W1 -A1000 -R -J -K -O $orient >> $psfile
