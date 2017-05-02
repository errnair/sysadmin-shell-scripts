#!/bin/bash
#################################################
#                                               #
#     A shell script to install Python3.        #
#                                               #
#################################################

# Check if gcc exists on the server
if hash gcc 2>/dev/null; then
	echo "\nGCC exists. Continuing with the installation."
else
	echo "\nInstalling the GCC compiler."
	yum install gcc -y > /dev/null 2>&1
fi

echo -e "\nInstalling developement tools required to build from source."
yum groupinstall "Development Tools" -y > /dev/null 2>&1
yum install zlib-devel -y > /dev/null 2>&1

echo -e "\nDownloading Python source..."
mkdir -p /opt/src/python3 > /dev/null 2>&1
cd /opt/src/python3/ > /dev/null 2>&1
wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tar.xz > /dev/null 2>&1

echo -e "\nUnzipping Python source..."
tar -xf Python-3.6.1.tar.xz > /dev/null 2>&1
cd Python-3.6.1 > /dev/null 2>&1
mkdir /usr/bin/python36/

echo -e "\nCompiling the Python source..."
./configure --prefix=/usr/bin/python36/ > /dev/null 2>&1
echo -e "\nBuilding from source..."
make > /dev/null 2>&1
make install > /dev/null 2>&1

echo -e "\nBuild complete. Creating symlinks."
ln -s /usr/bin/python36/bin/python3.6 /usr/bin/python3

echo -e "\n\nAll done.\nCheck the commands 'which python3' and 'python3 -V'\n"
