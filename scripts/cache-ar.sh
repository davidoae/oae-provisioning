#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt -qq update
apt install -qq --assume-yes redis-server

echo 'cache setup done'

