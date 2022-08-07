# BLACKOUT

Blackout networks using simple shell script

WPS Blackout - OneShot script  
Deauth Blackout - MDK4

## Installation

`sudo apt-get install -y gawk macchanger wpasupplicant python3 network-manager net-tools iw wget pixiewps mdk4 pkg-config libnl-3-dev libnl-genl-3-dev libpcap-dev && git clone https://github.com/rkhunt3r/blackout && cd blackout && chmod 775 blackout.sh`

## Usage
`sudo bash blackout.sh`

## Settings

`first_iface=wlan0` - (string) Interface to perform non-monitor mode attacks  
`second_iface=wlan1` - (string) Interface to perform monitor mode attacks  
`automode=0` - (boolean) Do not ask for target number, select all!    
`scan_accuracy=2` - (number) Repeat scan process x times  
`waiter=1` - (boolean) Wait before doing anything, if interface is busy
`blacklist=1` - (boolean) If attack fails, BSSID its added to blacklist. You can hide BSSID's that failed for next scan
