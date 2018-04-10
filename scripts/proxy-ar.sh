#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt -qq update
apt install -qq --assume-yes haproxy

echo 'proxy setup done'

