#!/bin/bash
#
# some of this should be in ansible, maybe all of it
#

NODE_VERSION=8.11.1
NPM_VERSION=4.6.1

export DEBIAN_FRONTEND=noninteractive
# pp servers only maybe...
apt -qq --assume-yes --no-install-recommends install openjdk-8-jre libreoffice libreoffice-writer ure libreoffice-java-common libreoffice-core libreoffice-common pdf2htmlex poppler-utils graphicsmagick ghostscript
apt -qq --assume-yes install abiword tidy
apt -qq --assume-yes install make g++

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
npm install -g grunt-cli

# symlink for grunt
ln -s /usr/src/node-v${NODE_VERSION}-linux-x64/bin/grunt /etc/alternatives/grunt
ln -s /etc/alternatives/grunt /usr/bin/grunt

echo 'qa setup done'

