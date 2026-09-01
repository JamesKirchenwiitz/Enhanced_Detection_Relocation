#
#
#

# module load gcc-12.2.0
# module load gcc-14.2.0
module load gcc-9.2.0

echo ph2dt
# /linux/mikeb/tomodd/hypodd/HYPODD.big/src/ph2dt/ph2dt ph2dt.inp
/mnt/raya/src/HypoDD/src/ph2dt/ph2dt ph2dt.inp

echo hypodd
set mod=6 # Ohio model
set mod=6s # Shannon model
set mod=6m # Mike model

# limit based on cc threshold
\mv dt.cc dt.cc.bak
awk '$3>.2' dt.cc.bak > ! dt.cc

\cp hypoDD.mod.$mod.inp hypoDD.inp
# /linux/mikeb/tomodd/hypodd/HYPODD.big/src/hypoDD/hypoDD hypoDD.inp
/mnt/raya/src/HypoDD/src/hypoDD/hypoDD hypoDD.inp
\cp hypoDD.reloc hypoDD.$1.reloc
\cp hypoDD.reloc hypoDD.mod.$mod.reloc
\cp hypoDD.log hypoDD.mod.$mod.log
# awk '{if (/ITERA/&&$2==8) i++; if (i&&(/absolute/||/weighted/)) print}' hypoDD.mod.$mod.log

### Noting how to increase the MAXDATA parameter for hypoDD
# cd /mnt/raya/src/HypoDD/include
# edit hypoDD.inc to adjust MAXDATA in the uncommented portion
# cd /mnt/raya/src/HypoDD/src
# module load gcc-12.2.0
# make
