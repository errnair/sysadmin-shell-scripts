#!/bin/bash
#################################################
#                                               #
# A shell script to install Jenkins on CentOS   #
#                                               #
#################################################

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

jvconfirm="y"

# Function to install Java using Yum
install_java() {
    echo -e "\nIn install_java\n"
    yum update -y
    yum install java -y
    java_version=$(java -version 2>&1 >/dev/null | grep 'version')
    echo -e "\n\nJava installation complete.\nJava version: $java_version\n\n"
    install_jenkins
}

# Function to install Jenkins using the Jenkins repo
install_jenkins() {
    echo -e "\nIn install_jenkins\n"
    yum install git -y
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    yum install jenkins -y
    chkconfig jenkins on

    firewall-cmd --zone=public --add-port=8080/tcp --permanent
    firewall-cmd --reload

    systemctl start jenkins
    systemctl status jenkins

    firewall-cmd --zone=public --add-port=8080/tcp --permanent
    firewall-cmd --reload

    local_ip=$(hostname -I)
    echo -e "\n\nJenkins installation is complete.\nAccess the Jenkins interface from http://$local_ip:8080\nThe default password is located at '/var/lib/jenkins/secrets/initialAdminPassword'\n\nExiting..."
    exit
}

# Check if Java is installed, and install Jenkins
if $(java -version 2>&1 >/dev/null | grep 'version'); then
    echo -e "\nJava is installed, proceeding with Jenkins installation."
    install_jenkins
else
    echo -e "\nJenkins requires Java to be installed. Proceed?(Y/n):"
    read jvconfirm
    if [ "$jvconfirm" == "y" ] || [ "$jvconfirm" = "Y" ]; then
        install_java
    elif [ "$jvconfirm" = "n" ] || [ "$jvconfirm" = "N" ]; then
        echo -e "\nJenkins requires Java to be installed first. Aborting install process..."
        exit
    else
        echo -e "\nInvalid input. Exiting..."
    fi
fi
