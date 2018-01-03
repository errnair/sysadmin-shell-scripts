#!/bin/bash

#######################################################################
# Script to generate random passwords using openssl                   #
# Usage: ./passgen.sh <number of passwords> <length of passwords>     #
#######################################################################

pass_num=$1
[ -n "$pass_num" ] || pass_num=1

pass_len=$2
[ -n "$pass_len" ] || pass_len=16

for i in $(seq 1 $pass_num);
do
      openssl rand -base64 48 | cut -c1-${pass_len};
done
