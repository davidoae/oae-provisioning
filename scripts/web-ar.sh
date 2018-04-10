#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
echo 'deb http://pkg.switch.ch/switchaai/ubuntu xenial main' > /etc/apt/sources.list.d/switch.list
curl http://pkg.switch.ch/switchaai/SWITCHaai-swdistrib.asc | apt-key add -
apt -qq update
apt install -qq --assume-yes --install-recommends shibboleth apache2

# adjust shibd startup timeout otherwise systemd will time out due to long metadata downloads
sed -i 's/TimeoutStartSec=5min/TimeoutStartSec=15min/' /etc/systemd/system/multi-user.target.wants/shibd.service

echo "web setup done"

