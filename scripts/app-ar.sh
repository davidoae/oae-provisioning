#!/bin/bash
#
# some of this should be in ansible, maybe all of it
#

NODE_VERSION=8.11.1

export DEBIAN_FRONTEND=noninteractive

# Download and extract node
cd /usr/src
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz
tar xzf node-v${NODE_VERSION}-linux-x64.tar.gz

# setup alternatives symlinks for node
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/node /etc/alternatives/node
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/npm /etc/alternatives/npm
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/lib/node_modules/pm2/bin/pm2 /etc/alternatives/pm2
ln -s /etc/alternatives/node /usr/bin/node
ln -s /etc/alternatives/npm /usr/bin/npm
ln -s /etc/alternatives/pm2 /usr/bin/pm2

echo 'qa setup done'

