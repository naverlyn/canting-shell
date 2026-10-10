free -h | awk '/Mem:/{print "Used\t"$3" / "$2; print "Available\t"$7; print "Cached\t"$6} /Swap:/{print "Swap\t"$3" / "$2}'
echo '#Top processes'
ps -eo %mem,comm --sort=-%mem --no-headers | head -5 | awk '{c=$1; $1=""; sub(/^ /,""); print $0"\t"c"%"}'
