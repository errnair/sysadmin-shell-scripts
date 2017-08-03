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

    yum install httpd mod_ssl -y
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
    echo -e "\n\nNagios Directory Location: /usr/local/nagios/"

    usermod -aG nagcmd apache
}

install_nagios_plugins() {
    cd /opt/sources/nagios
    mkdir nagios-plugins
    cd nagios-plugins/
    wget http://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz
    tar zxf nagios-plugins-*.tar.gz
    cd nagios-plugins-*
    ./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
    make
    make install
}

install_nrpe() {
    cd /opt/sources/nagios
    mkdir nrpe
    cd nrpe
    wget https://downloads.sourceforge.net/project/nagios/nrpe-3.x/nrpe-3.1.0.tar.gz
    tar zxf nrpe-*.tar.gz
    cd nrpe-*
    ./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib64/
    make all
    make install
    make install-config

    echo -e "nrpe\t\t5666/tcp\t\t# Nagios NRPE" >> /etc/services

    make install-init

    systemctl enable nrpe.service
    firewall-cmd --zone=public --add-port=5666/tcp
    firewall-cmd --zone=public --add-port=5666/tcp --permanent
    firewall-cmd --reload

    sed -i.bak 's/^\(dont_blame_nrpe=\).*/\11/' /usr/local/nagios/etc/nrpe.cfg
    ipaddr=$(hostname -I | cut -d" " -f 1)

}
