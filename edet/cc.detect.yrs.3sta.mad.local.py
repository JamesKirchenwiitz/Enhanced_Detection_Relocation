#!/software/python/anaconda3/bin/python3

from obspy import read, UTCDateTime as UTC
from obspy import Stream
from obspy.signal.cross_correlation import correlation_detector
import os
from pandas import read_csv
import sys
from statistics import median

sys.stdout.write("Command Format: cc.detect.yrs.netsta.py [template csv file] [yr1] [jd1] [yr2] [jd2] [sta1] [sta2] [sta3] \n")

print (sys.argv)
 
tempfile = sys.argv[1]
yr1 = int(sys.argv[2])
jd1 = int(sys.argv[3])
yr2 = int(sys.argv[4])
jd2 = int(sys.argv[5])
seq = sys.argv[6]
stan = "3sta"
stas = []
for i in range(7,10):
    stas.append(sys.argv[i])

print(stas)
temproot = tempfile.split("/")[len(tempfile.split("/"))-1]
tempname = temproot.split(".")[len(temproot.split("."))-2]
print(tempname)


data = read_csv(tempfile)
eps = data['epoch'].tolist()
picks = eps
picks = [UTC(x) for x in picks]
tempnums = eps
tempnums = [int(x) for x in tempnums]
mags = data['mag'].tolist()
ttpp = data['ttp'].tolist()
ttss = data['tts'].tolist()

# set frequency filter
freqmin=3
freqmax=15

stalist = read_csv('sta.csv')
stals = stalist['sta'].tolist()
cha1s = stalist['cha1'].tolist()
cha2s = stalist['cha2'].tolist()
cha3s = stalist['cha3'].tolist()
nets = stalist['net'].tolist()
locs = stalist['loc'].tolist()

if locs[0] == 0:
    locs[0]='00'

print(locs[0])

with open('match/match.'+seq+"."+str(tempname)+"."+stan+"."+str(yr1)+"."+str("%03d" % jd1)+"."+str(yr2)+"."+str("%03d" % jd2), 'w') as fp:
    pass

templates=[]
k = 0
mad = 0
for pick in picks:
    ttp = ttpp[k]
    tts = ttss[k]
    k += 1
    print(ttp,tts,pick)
    template=Stream()
    i = 0
    s = 0
    for sta in stals:
        net=nets[s]
        loc=locs[s]
        if loc == 0:
            loc='00'
        print(1,cha1s[s],cha2s[s],cha3s[s],s)
        chas=[cha1s[s],cha2s[s],cha3s[s]]
        s += 1
        for cha in chas:
         # Change filename path below to where ever you raw waveform data is stored:
            filename = "data/"+sta+"/"+str(pick.year)+"/"+sta+"."+net+"."+loc+"."+cha+"."+str(pick.year)+"."+str("%03d" % pick.julday)
            if os.path.getsize(filename) != 0:
                i += 1
                print(filename,i)
                temp = read(filename)
                if temp[0].stats.station == "O53A":
                    temp[0].stats.network = "OH"
                temp.filter('bandpass', freqmin=freqmin, freqmax=freqmax)
                temp.resample(40.0)
                if i == 1:
                    template += temp.slice(pick+ttp-5,pick+tts+15)
                else:
                    template += temp.slice(pick+tts-5,pick+tts+15)
                template.merge(fill_value='interpolate')
    templates.append(template)

for yr in range(yr1, yr2+1):
    ss = 1
    j1 = 1
    j2 = 366
    if yr == yr1:
        j1 = jd1

    if yr == yr2:
        j2 = jd2
        
    for jd in range(j1, j2+1):
        print(yr,jd)
        stream=Stream()
        ncha = 0
        s = 0
        for sta in stals:
            net=nets[s]
            loc=locs[s]
            if loc == 0:
                loc='00'
            chas=[cha1s[s],cha2s[s],cha3s[s]]
            print(cha1s[s],cha2s[s],cha3s[s])
            s += 1
            for cha in chas:
             # Change filename below to filepath where data is stored
                filename = "data/"+sta+"/"+str(yr)+"/"+sta+"."+net+"."+loc+"."+cha+"."+str(yr)+"."+str("%03d" % jd)
                if os.path.exists(filename):
                    if os.path.getsize(filename) != 0:
                        print(filename)
                        strm = read(filename)
                        if strm[0].stats.station == "O53A":
                            strm[0].stats.network = "OH"
                        strm.filter('bandpass', freqmin=freqmin, freqmax=freqmax)
                        strm.resample(40.0)
                        stream += strm
                        ncha += 1
        stream.merge(fill_value='interpolate')
        if ss == 1 or ss == 11 or ss == 22 or ss == 33 or mad == 0.9:
            height = 0.001  # similarity threshold
            distance = 5  # distance between detections in seconds
            detections, sims = correlation_detector(stream, templates, height, distance, template_times=picks, template_magnitudes=mags, template_names=tempnums )
            print("done mad detection")
            corrs=[]
            for item in detections:
                corrs.append(item['similarity'])
            if len(corrs) > 1:
                med=median(corrs)
                print("median=",med)
                medcorrs=[]
                for item in detections:
                    medcorrs.append(abs(item['similarity']-med))
                mad=median(medcorrs)
                tenmad = mad.tolist() * 8
                print("8mad=",tenmad)
            else:
                mad=0.9
                tenmad=0.9
          
        height = tenmad # similarity threshold
        distance = 5  # distance between detections in seconds
        ss += 1
        detections, sims = correlation_detector(stream, templates, height, distance, template_times=picks, template_magnitudes=mags, template_names=tempnums )
        with open('match/match.'+seq+"."+str(tempname)+"."+stan+"."+str(yr1)+"."+str("%03d" % jd1)+"."+str(yr2)+"."+str("%03d" % jd2), 'a') as filehandle:
            filehandle.writelines("%.2f %.5f %.5f %s %.2f %.4f %s\n" % (item['time'].timestamp,item['similarity'],mad,ncha,item['magnitude'],item['amplitude_ratio'],item['template_name']) for item in detections)
