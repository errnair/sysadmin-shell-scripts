#!/bin/bash
#################################################
#                                               #
# A shell script to install Squid on CentOS     #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

install_squid() {
    yum update -y
    yum install epel-release -y
    yum install squid -y
}

install_squid
