lscpu | awk -F: '
  /Model name/ { gsub(/^ +/, "", $2); print "Model\t" $2 }
  /^CPU\(s\):/ { gsub(/ /, "", $2); print "Threads\t" $2 }
  /CPU max MHz/ { printf "Max clock\t%.0f MHz\n", $2 }
'
awk '{ print "Load avg\t" $1 "  " $2 "  " $3 }' /proc/loadavg
echo '#Top processes'
ps -eo %cpu,comm --sort=-%cpu --no-headers | head -5 | awk '{ c = $1; $1 = ""; sub(/^ /, ""); print $0 "\t" c "%" }'
