#!/bin/bash
#################################################
#                                               #
# A shell script to set SELinux as 'permissive' #
# on CentoS.                                    #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

# Get current SELinux status
current_status=$(getenforce)
if [ $current_status = "Permissive" ]; then
    echo -e "\nSELinux is already set to 'Permissive'\nExiting..."
    exit
elif [ $current_status = "Disabled" ]; then
    echo -e "\nSELinux is already set to 'Disabled'.\nExiting..."
    exit
fi

# Disable SELinux
date=$(date +%Y-%m-%d)
cp -rf /etc/selinux/config /etc/selinux/config.backup-$date
sed -i 's/=enforcing/=permissive/g' /etc/selinux/config
setenforce 0

# Report changes
echo -e "\nSELinux has been set to Permissive.\n"
sestatus
echo -e "\n"
