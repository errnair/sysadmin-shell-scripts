#!/bin/bash
#################################################
#						#
#     A shell script to change the server's	#
#     hostname on CentOS 7. Uses 'hostnamectl'.	#
#						#
#################################################


new_hostname=""

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

# get user input for the new hostname
if [ "$1" != "" ]; then
    new_hostname=$1
else
    echo -e "Usage: ./change_hostname.sh <new hostname>\nPlease run the script once more WITH the new hostname."
    exit
fi

# detect original hostname
old_hostname=$(/usr/bin/hostnamectl | grep hostname | cut -d: -f2 | sed 's/^[[:space:]]*//')

# change hostname
/usr/bin/hostnamectl set-hostname $new_hostname
/usr/bin/systemctl restart network
/usr/bin/systemctl restart NetworkManager

# Print completion message
echo -e "\nHostname has been changed FROM $old_hostname TO $new_hostname.\nYou may need to log off and log back in from the shell session to see the changes reflected."
