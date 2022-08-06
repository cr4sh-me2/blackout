LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" |  awk '{print $1}' | while read line;
    do nmcli con up uuid $line &>/dev/null;
    done
