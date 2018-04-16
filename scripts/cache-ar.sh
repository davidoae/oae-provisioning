#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt install -qq --assume-yes redis-server

echo 'cache setup done'

