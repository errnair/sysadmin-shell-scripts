#!/bin/bash
#################################################
#                                               #
# A shell script to sync IMAP email accounts    #
# .                                             #
#################################################

host1=$1
user1=$2
pass1=$3

host2=$4
user2=$5
pass2=$6

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
    imapsync --host1 "$host1"  --user1 "$user1" --password1 "$pass1" --host2 "$host2" --user2 "$user2" --password2 "$pass2" --automap
    echo -e "\nEmail Sync complete...\n"
}

check_imapsync
sync_emails
