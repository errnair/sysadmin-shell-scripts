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

prerequisites(){
    yum update -y

}
