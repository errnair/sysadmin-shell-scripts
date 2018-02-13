#!/bin/bash
#################################################
#                                               #
#     A shell script to install Python3.        #
#                                               #
#################################################

# Check if gcc exists on the server
if hash gcc 2>/dev/null; then
	echo -e "\nGCC exists. Continuing with the installation."
else
	echo -e "\nInstalling the GCC compiler."
	yum install gcc -y > /dev/null 2>&1
fi

# Install packages required to build Python from source
echo -e "\nInstalling developement tools required to build from source."
yum groupinstall "Development Tools" -y > /dev/null 2>&1
yum install zlib-devel wget openssl-devel -y > /dev/null 2>&1

# To download Python 3's source from the official repository
echo -e "\nDownloading Python source..."
mkdir -p /opt/src/python3 > /dev/null 2>&1
cd /opt/src/python3/ > /dev/null 2>&1
wget https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz > /dev/null 2>&1

# Extract the Python source
echo -e "\nUnzipping Python source..."
tar -xf Python-3.6.4.tar.xz > /dev/null 2>&1
cd Python-3.6.4 > /dev/null 2>&1
mkdir /usr/bin/python36/

# Compile and build Python3 from the extracted source
echo -e "\nCompiling the Python source..."
./configure --prefix=/usr/bin/python36/ --enable-optimizations > /dev/null 2>&1
echo -e "\nBuilding from source..."
make > /dev/null 2>&1
make install > /dev/null 2>&1

# Create symlinks so that all the users on the system can use Python3
echo -e "\nBuild complete. Creating symlinks."
ln -s /usr/bin/python36/bin/python3.6 /usr/bin/python3

# Report status
echo -e "\n\nAll done.\nCheck the commands 'which python3' and 'python3 -V'\n"
