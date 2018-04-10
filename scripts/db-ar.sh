#!/bin/bash

# Ubuntu doesn't seem to provide cassandra themselves so grabbing it from apache
# openjdk-9-jre seems to cause cassandra silent segfault
apt -qq --assume-yes install openjdk-8-jre
echo "deb http://www.apache.org/dist/cassandra/debian 21x main" > /etc/apt/sources.list.d/cassandra.sources.list 
curl https://www.apache.org/dist/cassandra/KEYS | apt-key add -
apt -qq update
apt -qq --assume-yes install cassandra
systemctl stop cassandra.service
rm -r /var/lib/cassandra/*

echo "db setup done. Don't forget to set hosts file, copy up cassandra.yaml and start cassandra"

