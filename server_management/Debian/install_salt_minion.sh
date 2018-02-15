#!/bin/bash

#####################################################
#                                                   #
#  A shell script to install Salt-Minion on Debian  #
#                                                   #
#####################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

# Check if user-input exists
if [ "$1" != "" ]; then
    MASTERIP=$1
else
    echo -e "Usage: ./install_salt_minion.sh <salt-master-ip>\nPlease run the script once more WITH the Salt Master's IP address."
    exit
fi

# Function to install salt-minion
install_minion() {

    # Get the saltstack key and create the salt repo
    wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
    echo -e "deb http://repo.saltstack.com/apt/debian/8/amd64/latest jessie main" >> /etc/apt/sources.list.d/saltstack.list

    apt-get update

    # Install salt-minion and firewalld
    apt-get install salt-minion salt-ssh firewalld -y
    
    # Open the Salt-minon port
    firewall-cmd --zone=public --add-port=4506/tcp --permanent
    firewall-cmd --reload

    # Add the Salt-Master's IP to the minion's config file
    sed -i "s/\#master:\ salt/master:\ $MASTERIP/g" /etc/salt/minion
    
    # Enable and start the minion service
    systemctl enable salt-minion
    systemctl start salt-minion
}

# Calls the install_minion function
install_minion
