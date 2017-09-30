#!/bin/bash

#################################################
#                                               #
#    A shell script to install Salt Minion      #
#           on CentOS or Debian                 #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

salt_master=$1
os_type=$(gawk -F= '/^ID=/{print $2}' /etc/os-release)

check_master() {
    if [[ $salt_master == '' ]]; then
        echo -e "Usage: ./install_salt_minion.sh salt-master-ip   OR \nUsage: ./install_salt_minion.sh salt-master-hostname"
        exit
    fi
}

prerequisites_centos(){

    cat > /etc/yum.repos.d/saltstack.repo << saltrepo
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux \$releasever
baseurl=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest/SALTSTACK-GPG-KEY.pub
       https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest/base/RPM-GPG-KEY-CentOS-7
saltrepo

    yum update -y
    yum install systemd systemd-python -y
}

prerequisites_debian() {
    wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
    echo "deb http://repo.saltstack.com/apt/debian/8/amd64/latest jessie main" > /etc/apt/sources.list.d/saltstack.list
  
    apt-get upgrade -y
    apt-get update -y
    apt-get install systemd python-systemd -y
}

install_saltminion_centos() {
    yum install salt-common salt-minion salt-ssh -y
}

install_saltminion_debian() {
    apt-get install salt-common salt-minion salt-ssh -y
}

configure_saltminion() {
    systemctl enable salt-minion
    sed -i.bak "s/\#master\:\ salt/master\: $ip_address/g" /etc/salt/minion
    systemctl start salt-minion
}

check_master

if [[ $os_type == "\"centos\"" || $os_type == "\"rhel\"" ]]; then
    prerequisites_centos
    install_saltminion_centos
elif [[ $os_type == "debian" || $os_type == "ubuntu" ]]; then
    prerequisites_debian
    install_saltminion_debian
fi
