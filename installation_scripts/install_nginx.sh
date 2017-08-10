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

domain=$1

if [[ $domain == '' ]]; then
    echo -e "Usage: ./install_nginx domain-name.tld"
    exit
fi

install_nginx() {
    yum update -y
    echo -e "[nginx]\nname=nginx repo\nbaseurl=http://nginx.org/packages/rhel/7/\$basearch/\ngpgcheck=0\nenabled=1" >> /etc/yum.repos.d/nginx.repo
    yum install nginx -y
    systemctl enable nginx
    systemctl start nginx
    firewall-cmd --zone=public --add-service=http --permanent
    firewall-cmd --zone=public --add-service=https --permanent
    firewall-cmd --reload
    systemctl restart nginx
}
