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

prerequisites() {
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

    echo -e "\n\ndefine command{\n\tcommand_name check_nrpe\n\tcommand_line \$USER1\$/check_nrpe -H \$HOSTADDRESS\$ -c \$ARG1\$\n}" >> /usr/local/nagios/etc/objects/commands.cfg
    
    echo -e "\n\n######################\n   Enter the password for the Nagios Admin - 'nagiosadmin'\n######################\n\n"
    htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

    systemctl enable nagios

    echo -e "\nTesting Nagios configuration\n"
    /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

    echo -e "\nStarting Nagios service\n"
    systemctl start nagios
    systemctl restart nrpe.service
    systemctl restart httpd
}

post_installation() {
    cd
    yum install php php-mysql php-devel -y
    systemctl restart httpd

    chcon -R --reference=/var/www/html /usr/local/nagios/share
    chcon -R --reference=/var/www/html /usr/local/nagios/var
    chcon -R --reference=/var/www/cgi-bin /usr/local/nagios/sbin
    chcon -R -t httpd_sys_rw_content_t /usr/local/nagios/var/rw

    systemctl restart httpd

    echo -e "\nInstallation Complete..\nLogin using the URL: http://$ipaddr/nagios\nUsername:nagiosadmin\nPassword:<set up earlier>"
}

echo -e "\n\nInstalling prerequisites: Yum Update, Install Dev-Tools, Install Apache\n\n"
prerequisites
echo -e "\n\nInstalling Nagios\n\n"
install_nagios
echo -e "\n\nInstalling Nagios Plugins\n\n"
install_nagios_plugins
echo -e "\n\nInstalling NRPE\n\n"
install_nrpe
echo -e "\n\nConfiguring NRPE and Nagios\n\n"
configuration
echo -e "\n\nPost Installation: Apache context\n\n"
post_installation
