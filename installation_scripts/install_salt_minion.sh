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

os_type=$(gawk -F= '/^ID=/{print $2}' /etc/os-release)

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

if [[ $os_type == "\"centos\"" || $os_type == "\"rhel\"" ]]; then
    prerequisites_centos
    install_saltminion_centos
elif [[ $os_type == "debian" || $os_type == "ubuntu" ]]; then
    prerequisites_debian
    install_saltminion_debian
fi
