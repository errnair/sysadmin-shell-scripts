#!/bin/bash
#################################################
#                                               #
# A shell script to set SELinux as 'permissive' #
# on CentoS.                                    #
#                                               #
#################################################

# check if the current user is root
#if [[ $(/usr/bin/id -u) != "0" ]]; then
#    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
#    exit
#fi

install_jenkins() {
    echo -e "\nIn install_jenkins\n"
}

if hash java 2>/dev/null; then
    echo "Jenkins requires Java, but it isn't installed."
else
    install_jenkins
fi
