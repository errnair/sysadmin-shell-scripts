#!/bin/bash

conn_check=$(sudo netstat -p | grep tcp | grep ssh)

if [[ -z "$conn_check" ]];then
    echo $conn_check
else
    echo $conn_check
fi
