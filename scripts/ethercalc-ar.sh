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

# ethercalc systemd
cat > /etc/systemd/system/multi-user.target.wants/ethercalc.service <<EOF
[Unit]
Description=Ethercalc
Documentation=https://github.com/oaeproject/oae-ethercalc-docker
After=network.target

[Service]
Type=forking
User=ethercalc
Group=ethercalc
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/src/node-v${NODE_VERSION}-linux-x64/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
Environment=REDIS_HOST=proxy0
Environment=REDIS_PORT=6379
Environment=RABBIT_HOST=mq0
Environment=RABBIT_PORT=5672
Environment=PM2_HOME=/opt/ethercalc/.pm2
Environment=NODE_ENV=production
PIDFile=/opt/ethercalc/.pm2/pm2.pid

ExecStart=/usr/src/node-v${NODE_VERSION}-linux-x64/lib/node_modules/pm2/bin/pm2 resurrect
ExecReload=/usr/src/node-v${NODE_VERSION}-linux-x64/lib/node_modules/pm2/bin/pm2 reload all
ExecStop=/usr/src/node-v${NODE_VERSION}-linux-x64/lib/node_modules/pm2/bin/pm2 kill

[Install]
WantedBy=multi-user.target

EOF

# at this point everything should be ready
systemctl daemon-reload
# systemd start does a "pm2 resurrect" which means it needs a manual start the very first time
# as other server's hostnames are not yet available ansible will perform the initial app startup

echo "ethercalc setup done"

