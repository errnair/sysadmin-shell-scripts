#!/bin/bash
#################################################
#                                               #
#     A shell script create a new user - Nginx. #
#                                               #
#################################################

newuser=""

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

# get user input for the new hostname
if [ "$1" != "" ]; then
    newuser=$1
else
    echo -e "Usage: ./newuser.sh <new username>\nPlease run the script once more WITH the new username."
    exit
fi
