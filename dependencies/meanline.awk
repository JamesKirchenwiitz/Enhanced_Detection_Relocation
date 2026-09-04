{for(c=1;c<=NF;c++) {sum[c]+=$c; n[c]++} if (NF>nf) nf=NF}
END {for(c=1;c<=nf;c++) printf("%s ",sum[c]/n[c]); print ""}
