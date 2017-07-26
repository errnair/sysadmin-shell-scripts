#!/bin/bash
#################################################
#                                               #
# A shell script to install SaltStack on CentOS #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

prerequisites () {
    yum update -y
    yum install systemd systemd-python -y
    cp -rfv saltstack.repo /etc/yum.repos.d/saltstack.repo
}

install_saltmaster() {
    yum install salt salt-master salt-minion salt-ssh salt-cloud -y
    systemctl enable salt-master
    systemctl start salt-master
    systemctl status salt-master
    firewall-cmd --zone=public --add-port=4505/tcp --permanent
    firewall-cmd --zone=public --add-port=4506/tcp --permanent
}

install_saltminion() {
    yum install salt-minion salt-ssh -y
    systemctl enable salt-minion
    systemctl start salt-minion
    firewall-cmd --zone=public --add-port=4506/tcp --permanent
}

prerequisites
install_saltmaster
install_saltminion
