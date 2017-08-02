#!/bin/bash
#################################################
#                                               #
# A shell script to install Nagios on CentOS    #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

preresquisites() {
    yum update -y
    yum groupinstall "Development Tools" -y
    yum install xinetd openssl-devel net-snmp gd-devel gd -y

    groupadd nagcmd
    useradd -G nagcmd nagios

    yum install httpd mod_ssl
    systemctl enable httpd
    systemctl start httpd
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
}

install_nagios(){
    mkdir -p /opt/sources/nagios
    cd /opt/sources/nagios
    wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.1.tar.gz
    tar zxf nagios-*.tar.gz
    cd nagios-*
    ./configure --with-command-group=nagcmd
    make all
    make install
    make install-init
    make install-commandmode
    make install-config
    make install-webconf
    usermod -aG nagcmd apache

}

install_nagios_plugins() {
}
