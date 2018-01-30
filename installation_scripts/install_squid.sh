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

start_squid() {
    firewall-cmd --add-service=squid --permanent
    firewall-cmd --reload

    systemctl enable squid
    systemctl start squid
    systemctl status squid
}

restart_squid() {
    systemctl restart squid
}

backup_conf() {
    cp -fv /etc/squid/squid.conf "/etc/squid/squid.conf_bak-$(date +"%m-%d-%y")"
}

initial_conf() {
    touch /etc/squid/blocked_sites
}

install_squid
start_squid
backup_conf
initial_conf
restart_squid
