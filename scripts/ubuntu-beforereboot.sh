if [ "$1" = "" -o "$2" = "" ]
then
  echo "Usage: $0 <environment (production, staging)> <hostname>"
  exit
fi

SCRIPT_ENVIRONMENT=$1
SCRIPT_HOSTNAME=$2

# Set the host of the machine. Will need a reboot after this
#echo $SCRIPT_HOSTNAME > /etc/hostname
hostnamectl set-hostname $SCRIPT_HOSTNAME

sed -i "s/^127\.0\.0\.1[[:space:]]*localhost/127.0.0.1 $SCRIPT_HOSTNAME localhost/" /etc/hosts
# Also allow root access via ssh
sed -i 's/.* ssh-rsa /ssh-rsa /' /root/.ssh/authorized_keys

# Add everyone's keys
echo >> /root/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCfNTpIAkk0LPvOM+9cav4jbXYuiivAOJ/b3ulLPnfguzbSwQXqEXsu8FvIx8QoTTAOUx4v7VvMThrDkQp2uQUVAWRZy2WW3zLk4piZjLN9UDnhQQYu9obdSqeAQAMfMi9tCcIdwfirmjR83+B5OUkW93PP+5Y7pMWExpvH9r6q0w0sOo7S+SnF4RV71KMxNg62AkrgGF8XWZ5EURjCmNy3WH3W1Q1yiHFPKA3yWXMsW42QR3oTu6wcTuC7j1ZwU34v9XROZtIyGyom34/KOr9s6lAinBh1RDbmQxqsGIKvuov8kgTlsnPzzRtKLbFFUggeZflnLLvpWc/ZmSRTWiDUQy+R73NMSbWg6jTPs4lu8jLH2T/Rku6v4/eIbBL5QYstsr6eQ/zDy0eofoORPLv3DoDIh9+645fwB2wonXeNj04mtky5cnJRctieJh5Qe3C4m+jbfyHDR0EngIrvEvyjT1SoazOJv7vneRCV2F8mWxbMmkOjgOnX/4N8iJgDhWylxwDE6MIqNDVM6mnzpM9j4XHLnRUBcQJIViOs/SxaJIqWi8I6E08QBKV6JlP+UJdywXsq1Kue7aab6ilXmGf3+xn9LFi2BOf2paABwGWyE/ZnzKeRLokUO38t4c0x1hDFU5w0tH9kV1BTeeMO0LZbMz4V9yCNP9d4PdR8Epc9qQ== miguel.laginha@researchresearch.com
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0RoWMv8pGnN1T/OKbA8j70G66p0b9k+L50kLmJ1lcNZ7ZoFkYRV0YVyjlP9xoelVQjcTu/CKQsF3k+5K3mDiL7LwPXliWvLd/ENbsuapjzuyYV61v+tPyiuoIRc/3uP0bs0ASfZqH8WR9bO8z8ibEItp/5Q3rjz5VLzQVglkhNVVnqQzfAv1FqauG6zELFNwfXXmuVi/6eHyo88ywc/+KOC53e8zleaRscQQxBsxmCOi31bBLyssnFywRnVN/UBjqTZYfeP6crz/oJH0nXm14JYpieQNfabxzv7CP8nK1lqPt0wZHeq6DqhRmUWReSIpqecGYxl4QcPZ+gBW3yyHf david@Galileo
EOF
# for both root and ubuntu (for the moment)
cat /root/.ssh/authorized_keys > /home/ubuntu/.ssh/authorized_keys

export DEBIAN_FRONTEND=noninteractive
apt -qq update && apt -qq --assume-yes upgrade
apt -qq --assume-yes install python-minimal

# aws or ubuntu seem to have broken this somehow, maybe dhcp related but that's a guess
# although it is a behaviour change
# So we make up for it by setting the hostname again next boot
/bin/echo -e "#!/bin/bash\nhostnamectl set-hostname $SCRIPT_HOSTNAME\n" > /etc/rc.local

echo "Setup complete, needs a reboot to complete."

