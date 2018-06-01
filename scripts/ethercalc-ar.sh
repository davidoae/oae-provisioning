#!/bin/bash

# really, node 6.12.0? also what is su-exec and why we need it, looks suspicious
NODE_VERSION=6.12.0
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

npm install --silent -g pm2

export DEBIAN_FRONTEND=noninteractive
apt -qq --assume-yes install make g++

adduser --disabled-password --quiet --home /opt/ethercalc --no-create-home --gecos '' ethercalc
cd /opt
git clone https://github.com/oaeproject/ethercalc.git
ECDIR=/opt/ethercalc
cd $ECDIR
npm install --slient
chown -R ethercalc.ethercalc $ECDIR

echo "ethercalc setup done"

