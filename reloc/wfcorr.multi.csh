#
# Sciprt to create lag and corr files for hypodd from a set of SAC files
#  SAC files should be in a directory named sac
#  File 001 should have precise P and S picks on all stations and channels
#  User needs to specify the station names and channel types

# set num=`awk '{print $8;exit}' matches.txt | sort -u`
# set num=`awk '{print $NF;exit}' matches.txt | sort -u`
set num=$1
if (! -e lags.$num) mkdir lags.$num

foreach stacha ( "`cat stacha.txt`" )
  set sta=`echo $stacha | awk '{print $1}'`
  set cha=`echo $stacha | awk '{print $2}'`
  sbatch -t 2880 --partition=serial_onecore --output=logs/slurm-%j.out wfcorr.hpc.csh $num $sta $cha
end

  echo -n "waiting for wfcorr.hpc "
  while ( `squeue -o "%.8i %.6P %.175o %.8u %.2t %.10M %.6D %R" | grep wfcorr | grep $sta | grep $cha | grep -c $num ` )
    echo -n "."
    sleep 30
  end
