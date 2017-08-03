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

ipaddr=$(hostname -I | cut -d" " -f 1)

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
}

configuration() {
    sed -i.bak 's/^\(dont_blame_nrpe=\).*/\11/' /usr/local/nagios/etc/nrpe.cfg
    sed -i "s/^\(allowed_hosts=127.0.0.1,::1\).*/\1,$ipaddr/" /usr/local/nagios/etc/nrpe.cfg
    
    systemctl start nrpe.service

    echo -e "\nlocalhost\n/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1\n" >> /tmp/nrpe_test.txt
    /usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 >> /tmp/nrpe_test.txt
    echo -e "\nIP\n/usr/local/nagios/libexec/check_nrpe -H $ipaddr\n" >> /tmp/nrpe_test.txt
    /usr/local/nagios/libexec/check_nrpe -H $ipaddr >> /tmp/nrpe_test.txt

    sed -i "s/^\(command\[check_load\]=\/usr\/local\/nagios\/libexec\/check_load\).*/\1\ \-w\ 15,10,5\ \-c\ 30,25,20/" /usr/local/nagios/etc/nrpe.cfg
    systemctl restart nrpe.service

    echo -e "\ncheck_load\n/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 -c check_load\n" >> /tmp/nrpe_test.txt
    /usr/local/nagios/libexec/check_nrpe -H 127.0.0.1 -c check_load >> /tmp/nrpe_test.txt

    echo "cfg_dir=/usr/local/nagios/etc/servers" >> /usr/local/nagios/etc/nagios.cfg
    mkdir /usr/local/nagios/etc/servers

    sed -i 's/nagios@localhost/admin@localhost/g' /usr/local/nagios/etc/objects/contacts.cfg


}
