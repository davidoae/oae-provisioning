#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt install -qq --assume-yes nagios3 nagios-nrpe-plugin nagios-plugins-rabbitmq nagios-plugins-contrib

echo "nagios setup done"

