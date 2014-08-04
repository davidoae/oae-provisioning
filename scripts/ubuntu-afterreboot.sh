# Puppet should run after a reboot
sed -i "s/START=no/START=yes/" /etc/default/puppet