#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt -qq update

# Syslog config
rm -f /etc/rsyslog.d/*
echo '

# Allow for very large messages to be logged. This needs to go before any network related
# configuration gets set
$MaxMessageSize 32k

module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support

# Use traditional timestamp format.
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# Filter duplicated messages
$RepeatedMsgReduction on

# Set the default permissions for all log files.
$FileOwner syslog
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog

# Where to place spool and state files
$WorkDirectory /var/spool/rsyslog

$SystemLogRateLimitInterval 0

# Provides TCP forwarding. The IP is the server IP address
#*.* @@###syslog serer ip and uncomment###
' > /etc/rsyslog.conf

apt install -qq --assume-yes rabbitmq-server

systemctl stop rabbitmq-server

echo 'RABBITMQ_NODE_PORT=5672' > /etc/rabbitmq/rabbitmq-env.conf
echo '[rabbitmq_management].' > /etc/rabbitmq/enabled_plugins
echo -e "[\n{rabbit, [{cluster_nodes, ['rabbit@mq0', 'rabbit@mq1']}]}\n]." > /etc/rabbitmq/rabbitmq.config
echo -n PICAKWYNROUIOHRXOUYO > /var/lib/rabbitmq/.erlang.cookie

echo 'mq setup done, start rabbit manually;'
echo -e '  systemctl start rabbitmq-server.service\n  rabbitmqctl stop_app\n  rabbitmqctl  join_cluster rabbit@mq0\n  rabbitmqctl start_app'

