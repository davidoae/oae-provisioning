#!/bin/bash

NODE_VERSION=8.11.1
NPM_VERSION=4.6.1

export DEBIAN_FRONTEND=noninteractive

# nginx first to avoid collisions with apache
apt install -qq --assume-yes --install-recommends nginx
systemctl stop nginx

# now shib and apache
echo 'deb http://pkg.switch.ch/switchaai/ubuntu xenial main' > /etc/apt/sources.list.d/switch.list
curl http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc | apt-key add -
apt -qq update
apt install -qq --assume-yes --install-recommends shibboleth apache2
systemctl stop apache2
systemctl stop shibd

# adjust shibd startup timeout otherwise systemd will time out due to long metadata downloads
sed -i 's/TimeoutStartSec=5min/TimeoutStartSec=15min/' /etc/systemd/system/multi-user.target.wants/shibd.service

### node

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

# Need older verson of npm
npm install -g npm@$NPM_VERSION
#npm install -g grunt-cli

# symlink for grunt
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/grunt /etc/alternatives/grunt
ln -s /etc/alternatives/grunt /usr/bin/grunt

echo "web setup done"

