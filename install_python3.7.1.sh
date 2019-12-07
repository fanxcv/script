#!/bin/bash
mkdir /usr/local/python3tmp
cd /usr/local/python3tmp
wget https://www.python.org/ftp/python/3.7.1/Python-3.7.1.tgz
tar xvf Python-3.7.1.tgz
cd Python-3.7.1
yum -y install gcc zlib-devel openssl-devel libffi-devel sqlite-devel
./configure --prefix=/usr/local/python3
make
make install
ln -s /usr/local/python3/bin/python3 /usr/bin/python3
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
pip3 install --upgrade pip
rm -rf /usr/local/python3tmp
