df -h --output=target,size,used,pcent -x tmpfs -x devtmpfs -x efivarfs -x squashfs -x overlay | tail -n +2 | awk '
  $1 == "/" || $1 == "/home" || $1 ~ /^\/boot/ || $1 ~ /^\/mnt\// || $1 ~ /^\/run\/media\// { print $1 "\t" $3 " / " $2 "\t" $4 }
'
