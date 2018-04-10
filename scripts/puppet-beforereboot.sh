#!/bin/bash

# Set the host
echo puppet >/etc/hostname
sed -i 's/^127\.0\.0\.1[[:space:]]*localhost/127.0.0.1 localhost puppet/' /etc/hosts
sed -i 's/.* ssh-rsa /ssh-rsa /' /root/.ssh/authorized_keys
echo 'Host has been set. Reboot the machine then run the after-reboot script.'
