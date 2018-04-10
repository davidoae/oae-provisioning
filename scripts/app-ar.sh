#!/bin/bash

NODE_VERSION=6.11.5

# Download and extract node
cd /usr/src
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz
tar xzf node-v${NODE_VERSION}-linux-x64.tar.gz

# setup alternatives symlinks for node
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/node /etc/alternatives/node
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/npm /etc/alternatives/npm
ln -s /etc/alternatives/node /usr/bin/node
ln -s /etc/alternatives/npm /usr/bin/npm

# give ubuntu user direct access to oae dirs
chown ubuntu /opt

echo 'app setup done'

