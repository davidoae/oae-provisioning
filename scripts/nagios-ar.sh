#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt install -qq --assume-yes nagios3 nagios-nrpe-plugin nagios-plugins-rabbitmq nagios-plugins-contrib

# for some weird-ass reason the nagios-plugins-rabbitmq package puts it's check_* commands somewhere nagios doesn't look
ln -s /usr/lib/nagios/plugins-rabbitmq/* /usr/lib/nagios/plugins/

echo "nagios setup done"

