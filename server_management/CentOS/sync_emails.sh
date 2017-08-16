#!/bin/bash
#################################################
#                                               #
# A shell script to set SELinux as 'permissive' #
# on CentoS.                                    #
#                                               #
#################################################

user1=$1
pass1=$2

user2=$3
pass2=$4

# check if the current user is root
if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo -e "This looks like a 'non-root' user.\nPlease switch to 'root' and run the script again."
    exit
fi

install_imapsync() {
    yum install epel-release
    yum install imapsync
}

check_imapsync() {
    if hash imapsync 2>/dev/null; then
        echo -e "\nImapSync exists. Continuing with the syncing process"
    else
        echo -e "\nInstalling ImapSync."
        install_imapsync
    fi
}

sync_emails() {
    echo -e "\nSyncing emails now...\n"
    echo -e "\nEmail Sync complete...\n"
}
