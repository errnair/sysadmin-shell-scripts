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

jvconfirm="y"

install_java() {
    echo -e "\nIn install_java\n"
}
install_jenkins() {
    echo -e "\nIn install_jenkins\n"
}

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
