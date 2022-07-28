#!/usr/bin/env awk -f

#SOURCE: https://github.com/dmitrygrey/awk_iw_grab
#MODDED BY @rkhunt3r

$1 ~ /^BSS/ {
    if($2 !~ /Load:/) { #< Escape "BBS Load:" line
        gsub("(\\(.*)", "", $2)
        MAC = toupper($2)
        wifi[MAC]["enc"] = "OPEN"
        wifi[MAC]["WPS"] = "no"
    }
}
$1 == "SSID:" {
    # Workaround spaces in SSID
    FS=":" #< Changing field separator on ":", it should be
           #  forbidded sign for SSID name
    $0=$0
    sub(" ", "", $2) #< remove first whitespace
    wifi[MAC]["SSID"] = $2
    FS=" "
    $0=$0
}

$1 == "WPS:" {
    wifi[MAC]["WPS"] = "yes"
}
$1 == "DS" {
    wifi[MAC]["Ch"] = $5
}
$1 == "signal:" {
    match($2, /-([0-9]{2})\.00/, m)
    wifi[MAC]["Sig"] = m[1]
}
END {
    for (w in wifi) {
        printf "%s %s %s %s %s\n", wifi[w]["Sig"], wifi[w]["SSID"], w, \
               wifi[w]["WPS"], wifi[w]["Ch"]
    }
}
