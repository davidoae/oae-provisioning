#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt install -qq --assume-yes rabbitmq-server
systemctl stop rabbitmq-server

echo 'mq setup done'

