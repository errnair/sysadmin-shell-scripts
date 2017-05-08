#!/bin/bash
#################################################
#                                               #
#     A tiny script to create a MySQL DB, a     #
#     MySQL user and grant privileges to the    #
#     new user as required.                     #
#                                               #
#################################################

# get user input for the new hostname
if [ "$1" != "" ]; then
    rootpass="$1"
else
    echo -e "Usage: ./create_db.sh <mysql root password>\nPlease run the script once more WITH the new hostname."
    exit
fi

# Create the MySQL DB
mysql -uroot -p$rootpass -e"drop database if exists test_db;"
mysql -uroot -p$rootpass -e"create database test_db;"

# Create the MySQL User
mysql -uroot -p$rootpass -e"create user test_user;"

# Grant privileges
mysql -uroot -p$rootpass -e"grant all privileges on test_db.* to 'test_user'@'localhost' identified by 'test@123';"
