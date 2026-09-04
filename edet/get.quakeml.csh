#!/bin/csh
#
# Script to get USGS QuakeML that has picks in it
#

module load gmt

# Select file:
set catfile=getcatpy.soutx.txt
set lon1=`minmax -C $catfile | awk '{print $5-($6-$5)*.05}'`
set lon2=`minmax -C $catfile | awk '{print $6+($6-$5)*.05}'`
set lat1=`minmax -C $catfile | awk '{print $3-($4-$3)*.05}'`
set lat2=`minmax -C $catfile | awk '{print $4+($4-$3)*.05}'`
set dat1=2020-01-01 dat2=2025-04-01 set region=soutx-soutx mag1=1

wget "https://earthquake.usgs.gov/fdsnws/event/1/query?starttime=${dat1}&endtime=${dat2}&minlatitude=${lat1}&maxlatitude=${lat2}&minlongitude=${lon1}&maxlongitude=${lon2}&minmagnitude=${mag1}&format=text" -O events.$region.usgs.txt

awk -F "|" '{if (NR==1) print "1970-01-01T00:00:00"; else print $2}' events.$region.usgs.txt | toepoch.csh | paste - events.$region.usgs.txt | awk -F "|" '{print $1}' >! events.$region.usgs.name.txt

wget "https://earthquake.usgs.gov/fdsnws/event/1/query?starttime=${dat1}&endtime=${dat2}&minlatitude=${lat1}&maxlatitude=${lat2}&minlongitude=${lon1}&maxlongitude=${lon2}&minmagnitude=${mag1}&format=quakeml" -O events.$region.usgs.xml

awk -F '"' '{gsub("quakeml:","https://");gsub("origin","phase-data");gsub("product.xml","quakeml.xml");print $18}' events.$region.usgs.xml | awk 'NF==1' >! events.$region.usgs.links
# awk -F '"' '/tx2023aoco/{gsub("quakeml:","https://");gsub("origin","phase-data");gsub("product.xml","quakeml.xml");print $18}' events.$region.usgs.xml >! events.$region.usgs.links
#awk -F '"' '/tx2023aoms/{gsub("quakeml:","https://");gsub("origin","phase-data");gsub("product.xml","quakeml.xml");print $18}' events.$region.usgs.xml >! events.$region.usgs.links

foreach link (`cat events.$region.usgs.links`)
  set name=`echo $link | awk -F "/" '{print $6}'`
  set ep=`echo $link | awk -F "/" '{print $8}'`
  echo $name $ep 
  wget -O quakeml/quakeml.$name.xml $link
end

exit

# wget https://earthquake.usgs.gov/product/phase-data/tx2024dijp/tx/1710266903084/quakeml.xml
