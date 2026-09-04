#!/software/python/anaconda3/bin/python3
# ^ change path depending on system

##################
# Working Script
##################

import obspy
import obsplus
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from obspy.clients.fdsn import Client
from obspy import UTCDateTime
import datetime
import calendar
import datetime as dt
client = Client("USGS") 

# specify duration of catalog search
starttime = UTCDateTime("2023-09-01T00:00:00")
endtime = UTCDateTime("2023-11-01T00:00:00")


###################
# Reading in events
###################

# Box search (these are the settings used for KTFZ)
events = client.get_events(starttime=starttime, endtime=endtime, minlatitude=28.65, maxlatitude=29.35, minlongitude=-98.5, maxlongitude=-97.35, minmagnitude=0)

# Radius search
#events = client.get_events(starttime=starttime, endtime=endtime, latitude=28.939, longitude=-98.037,
#maxradius = 0.09, minmagnitude = 2)

# Creating dataframe
df = obsplus.events_to_df(events)

#############################
# making df match hpc command
#############################

# changing column names to match
df = df.rename(columns = {'time' : 'decyear', 'latitude' : 'lat',
                          'longitude' : 'lon', 'depth' : 'dep', 'magnitude' : 'mag'})

# converting to epoch time
df['epoch'] = [d.timestamp() for d in df['decyear']]
df['epoch'] = [int(d) for d in df['epoch']]

# setting baseline epoch time at 2020 like hpc command
et = dt.datetime(2020, 1, 1).timestamp()
et = int(et)

# creating decyear column exactly like the hpc command
df['decyear'] = [((d - et)/86400/365.25 + 2020) for d in df['epoch']]


# rounding decyear, epoch, lat, & lon columns to match jan2023.csv
df['decyear'] = df['decyear'].round(7)
df['lat'] = df['lat'].round(4)
df['lon'] = df['lon'].round(4)
df['dep'] = df['dep'] / 1000
df['dep'] = df['dep'].round(3)

# narrowing columns for manipulations sake
df = df[['epoch', 'decyear', 'lat', 'lon', 'dep', 'mag']]

# Turning dataframe into csv file
# change "soutx" to whatever input you want, file structure must stay for template matching
df.to_csv('getcatpy.soutx.csv', index = False)
print(len(df))
print('Done')
