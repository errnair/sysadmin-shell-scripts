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

echo "\nCreating new user and adding the user to the 'wheel' group"
useradd $newuser
usermod -aG wheel $newuser

echo "\nCreating webroot and log locations, and assigning required permissions"
mkdir /home/$newuser/public_html
mkdir /home/$newuser/logs
chcon -Rt httpd_log_t /home/$newuser/logs/
chcon -Rt httpd_sys_content_t /home/$newuser/public_html/
chmod 711 /home/$newuser/
chown -R $newuser:$newuser /home/$newuser/

echo "Creating Python3 virtual environment in $newuser's webroot"
su - $newuser
cd public_html
python3 -m venv flaskr_env
