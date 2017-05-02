#!/bin/bash

echo -e "===== SYSTEM and HARDWARE INFO ====="
freemem=$(free -m | awk 'NR==2 {print $4 " MB"}')
ramspeed=$(dmidecode --type 17 | grep Speed | head -1 | sed 's/^[[:space:]]*//')
ramtype=$(dmidecode --type 17 | grep Type: | head -1 | sed 's/^[[:space:]]*//' | awk {'print $2'})
cpumodel=$(lscpu | grep Model\ name | cut -d: -f2 | sed 's/^[[:space:]]*//')
cpunums=$(grep -c '^processor' /proc/cpuinfo)
kernel=$(uname -r)
osinfo=$(cat /etc/redhat-release)
publicip=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
privateip=$(ip -4 addr | grep inet | awk {'print $2'} | cut -d/ -f1)

echo -e "\n1. OS version: $osinfo\n"
echo -e "\n2. Kernel Info: $kernel\n"
echo -e "\n3. Free Memory: $freemem\n"
echo -e "\n4. RAM Speed: $ramspeed\n"
echo -e "\n5. RAM Type: $ramtype\n"
echo -e "\n6. Number of Processors: $cpunums\n"
echo -e "\n7. CPU Model: $cpumodel\n"
echo -e "\n8. Current Disk Usage:\n"
df -h | awk 'NR>1 {print $4 " free on " $1}' 2>/dev/null
echo -e "\n9. Private IPs: \n$privateip\n"
echo -e "\n10. Public IPs: \n$publicip\n"


