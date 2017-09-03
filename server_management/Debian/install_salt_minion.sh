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

MASTERIP=$1

install_minion() {
    wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
    echo -e "deb http://repo.saltstack.com/apt/debian/8/amd64/latest jessie main" >> /etc/apt/sources.list.d/saltstack.list
    apt-get update
    apt-get install salt-minion salt-ssh firewalld -y
    
    firewall-cmd --zone=public --add-port=4506/tcp --permanent
    firewall-cmd --reload

    sed -i "s/\#master:\ salt/master:\ $MASTERIP/g" /etc/salt/minion
    
    systemctl enable salt-minion
    systemctl start salt-minion
}

install_minion
