#!/bin/bash
#################################################
#                                               #
#  A shell script to install Nginx and Flask    #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

domain=$1
username=$(echo $domain | cut -d. -f1)
ipaddr=$(hostname -I)

check_domain() {
    if [[ $domain == '' ]]; then
        echo -e "Usage: ./install_nginx domain-name.tld"
        exit
    elif [[ $(grep -o "\." <<< "$domain" | wc -l) > 1 || $(grep -o "\." <<< "$domain" | wc -l) < 1 ]]; then
        echo -e "Invalid domain! Usage: ./install_nginx domain-name.tld"
        exit
    fi
}

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

create_user() {
    useradd -s /sbin/nologin $username
    chmod go+x /home/$username

    mkdir /home/$username/logs
    mkdir /home/$username/public_html

    chcon -Rvt httpd_log_t /home/$username/logs/
    chcon -Rvt httpd_sys_content_t /home/$username/public_html/

    echo -e "<html>\n<head>\n\t<title>NGINX - TEST</title>\n</head>\n<body>\n\t<h3>THIS IS A TEST<h3>\n\t<h4>Index file loaded from /home/$username/public_html/<h4>\n</body>\n</html>" >> /home/$username/public_html/index.html

    chown -Rv $username:$username /home/$username
}

create_vhost() {
    cp -fv /etc/nginx/nginx.conf "/etc/nginx/nginx.conf_bak-$(date +"%m-%d-%y")"
    mkdir /etc/nginx/sites-available
    mkdir /etc/nginx/sites-enabled

    awk '
    { print }
    /etc\/nginx\/conf.d\/\*/ {
    print "    include /etc/nginx/sites-enabled/*.conf;"
    }
    ' /etc/nginx/nginx.tmp.conf > /etc/nginx/nginx.tmp.conf && mv /etc/nginx/nginx.tmp.conf /etc/nginx/nginx.conf

    cat > /etc/nginx/sites-available/$username.com.conf <<nginx
server {
    listen  80;

    server_name $username.com www.$username.com;
    access_log /home/$username/logs/access.log;
    error_log /home/$username/logs/error.log;

    location / {
        root  /home/$username/public_html;
        index  index.html index.htm index.php;
        try_files \$uri \$uri/ =404;
    }

    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
        root  /usr/share/nginx/html;
    }
}
nginx

    ln -sv /etc/nginx/sites-available/$username.com.conf /etc/nginx/sites-enabled/$username.com.conf
    nginx -t
    systemctl restart nginx
}

install_python3() {
    if hash gcc 2>/dev/null; then
        echo "\nGCC exists. Continuing with the installation."
    else
        echo "\nInstalling the GCC compiler."
        yum install gcc -y > /dev/null 2>&1
    fi 
    
    echo -e "\nInstalling developement tools required to build from source."
    yum groupinstall "Development Tools" -y > /dev/null 2>&1
    yum install zlib-devel wget openssl-devel -y > /dev/null 2>&1

    echo -e "\nDownloading Python source..."
    mkdir -p /opt/src/python3 > /dev/null 2>&1
    cd /opt/src/python3/ > /dev/null 2>&1
    wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tar.xz > /dev/null 2>&1

    echo -e "\nUnzipping Python source..."
    tar -xf Python-3.6.1.tar.xz > /dev/null 2>&1
    cd Python-3.6.1 > /dev/null 2>&1
    mkdir /usr/bin/python36/

    echo -e "\nCompiling the Python source..."
    ./configure --prefix=/usr/bin/python36/ --enable-optimizations > /dev/null 2>&1
    echo -e "\nBuilding from source..."
    make > /dev/null 2>&1
    make install > /dev/null 2>&1

    echo -e "\nBuild complete. Creating symlinks."
    ln -s /usr/bin/python36/bin/python3.6 /usr/bin/python3

    echo -e "\n\nAll done.\nCheck the commands 'which python3' and 'python3 -V'\n"

}

create_venv() {
    su - $username; cd public_html
    python3 -m venv flask_demoenv
    source flask_demoenv/bin/activate

    # Download from VCS

    python3 -m pip install -r requirements.txt
    deactivate; logout
}

configure_webserver(){

}

check_domain
install_nginx
create_user
create_vhost
install_python3

chsh -s /bin/bash $username

create_venv
configure_webserver

echo -e "\n\nInstallation complete.\nNow, add the following line to your local 'hosts' file (/etc/hosts in *nix systems)\n\n$ipaddr\t$domain www.$domain\n\nExiting..."
