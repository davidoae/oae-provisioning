#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <environment (production, performance)>"
  exit
fi

SCRIPT_ENVIRONMENT=$1

# Install the puppetlabs repos
chmod 1777 /tmp
cd /tmp
wget --no-verbose http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb

# Pull in packages from the puppetlabs repos
apt-get -qq update

# Install git and puppetmaster, ensuring right version of libapache2-mod-passenger
apt-get -qq -y install git puppetmaster-passenger puppetdb puppetdb-terminus libapache2-mod-passenger=2.2.11debian-2 python-software-properties
# some of these cause issues on the latest version so have set versions specifically
puppet module install puppetlabs-stdlib --version 4.5.1
puppet module install puppetlabs-concat --version 1.2.0
puppet module install puppetlabs-apt --version 1.8.0
puppet module install puppetlabs-firewall --version 1.4.0
puppet module install puppetlabs-postgresql --version 4.2.0
puppet module install puppetlabs-inifile --version 1.2.0
puppet module install puppetlabs-puppetdb --version 4.1.0

# Configure PuppetMaster
cat > /etc/puppet/puppet.conf <<EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
templatedir=\$confdir/templates
pluginsync=true
environment=$SCRIPT_ENVIRONMENT

[master]
storeconfigs=true
storeconfigs_backend=puppetdb

# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN 
ssl_client_verify_header = SSL_CLIENT_VERIFY

# Use puppet-hilary checkout
modulepath = \$confdir/puppet-hilary/environments/\$environment/modules:\$confdir/puppet-hilary/modules:\$confdir/modules
manifest = \$confdir/puppet-hilary/site.pp
reports = store, http
reporturl = http://puppet/reports/upload

[agent]
report=true
EOF

cat > /etc/puppet/puppetdb.conf <<EOF
[main]
server = puppet
port = 8081
EOF

cat > /etc/puppet/hiera.yaml <<EOF
:backends:
  - json
:json:
  :datadir: /etc/puppet/puppet-hilary/environments/%{::environment}/hiera
:hierarchy:
  - %{::clientcert}_hiera_secure
  - %{::clientcert}
  - %{nodetype}_hiera_secure
  - %{nodetype}
  - common_hiera_secure
  - common
EOF


cat > /etc/default/puppet <<EOF
# Defaults for puppet - sourced by /etc/init.d/puppet

# Start puppet on boot?
START=yes

# Startup options
DAEMON_OPTS=""
EOF

# Automatically sign all client certificates. Only machines in our vlan can access the puppet interface
echo "*" > /etc/puppet/autosign.conf

git clone --quiet git://github.com/oaeproject/puppet-hilary /etc/puppet/puppet-hilary
cd /etc/puppet/puppet-hilary
git fetch origin
bin/pull.sh

# an attempt to give the admin time to upload common_hiera_secure.json
myiptemp="$(ip a show dev eth0 | awk '/inet / { print $2 }')"
echo -e "\e[0;31mWaiting 30s to give time for admin to upload common_hiera_secure.json"
echo "Try this;"
echo "  scp common_hiera_secure.json root@${myiptemp%%/*}:/etc/puppet/puppet-hilary/environments/${SCRIPT_ENVIRONMENT}/hiera/common_hiera_secure.json"
echo -e "\e[0m"
sleep 30

## Puppet Dashboard

# Set root password to "root" for the upcoming mysql prompt
echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

apt-get -qq -y install build-essential irb libmysql-ruby libmysqlclient-dev libopenssl-ruby libreadline-ruby mysql-server rake rdoc ri ruby ruby-dev

# Install rubygems (do not use the installation that came w/ OS)
URL="http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz"
PACKAGE=$(echo $URL | sed "s/\.[^\.]*$//; s/^.*\///")

cd $(mktemp -d /tmp/install_rubygems.XXXXXXXXXX) && \
wget -c -t10 -T20 --no-verbose $URL && \
tar xfz $PACKAGE.tgz && \
cd $PACKAGE && \
ruby setup.rb

update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.8 1
apt-get -qq -y install puppet-dashboard

# Create 'dashboard' user with password 'dashboard'
mysql -u root -proot -e "CREATE DATABASE dashboard CHARACTER SET utf8;"
mysql -u root -proot -e "CREATE USER 'dashboard'@'localhost' IDENTIFIED BY 'dashboard';"
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON dashboard.* TO 'dashboard'@'localhost';"

cat > /usr/share/puppet-dashboard/config/database.yml <<EOF
production:
    database: dashboard
    username: dashboard
    password: dashboard
    encoding: utf8
    adapter: mysql
EOF
chmod 660 /usr/share/puppet-dashboard/config/database.yml

# Deploy the database
cd /usr/share/puppet-dashboard
sed -i 's/max_allowed_packet.*/max_allowed_packet = 32M/g' /etc/mysql/my.cnf
service mysql restart
rake RAILS_ENV=production db:migrate

# Make an init script for puppetmaster (since we're using passenger, we'll just bounce apache)
ln -s /etc/init.d/apache2 /etc/init.d/puppetmaster

# Set up the apache configs for puppetmaster and dashboard
rm -f /etc/apache2/sites-enabled/*
cat > /etc/apache2/sites-enabled/000-puppetmaster <<EOF
PassengerHighPerformance on
PassengerMaxPoolSize 12
PassengerPoolIdleTime 1500
# PassengerMaxRequests 1000
PassengerStatThrottleRate 120
RackAutoDetect Off
RailsAutoDetect On

Listen 8140

<VirtualHost *:8140>
SSLEngine on
SSLProtocol -ALL +SSLv3 +TLSv1
SSLCipherSuite ALL:!ADH:RC4+RSA:+HIGH:+MEDIUM:-LOW:-SSLv2:-EXP

SSLCertificateFile      /var/lib/puppet/ssl/certs/puppet.pem
SSLCertificateKeyFile   /var/lib/puppet/ssl/private_keys/puppet.pem
SSLCertificateChainFile /var/lib/puppet/ssl/certs/ca.pem
SSLCACertificateFile    /var/lib/puppet/ssl/certs/ca.pem
# If Apache complains about invalid signatures on the CRL, you can try disabling
# CRL checking by commenting the next line, but this is not recommended.
SSLCARevocationFile     /var/lib/puppet/ssl/ca/ca_crl.pem
SSLVerifyClient optional
SSLVerifyDepth  1
SSLOptions +StdEnvVars

RequestHeader set X-SSL-Subject %{SSL_CLIENT_S_DN}e
RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

DocumentRoot /usr/share/puppet/rack/puppetmasterd/public/
RackBaseURI /
<Directory /usr/share/puppet/rack/puppetmasterd/>
Options None
AllowOverride None
Order allow,deny
allow from all
</Directory>
</VirtualHost>
EOF

cat > /etc/apache2/sites-enabled/010-dashboard <<EOF
<VirtualHost *:80>
DocumentRoot /usr/share/puppet-dashboard/public/
<Directory /usr/share/puppet-dashboard/public/>
    Options None
    Order allow,deny
    allow from all
</Directory>
ErrorLog /var/log/apache2/dashboard.error.log
LogLevel warn
CustomLog /var/log/apache2/dashboard.access.log combined
ServerSignature On
</VirtualHost>
EOF

service apache2 restart

# Enable the dashboard workers
sed -i 's/### START=no/START=yes/g' /etc/default/puppet-dashboard-workers
touch /usr/share/puppet-dashboard/log/production.log
chmod 0666 /usr/share/puppet-dashboard/log/production.log
service puppet-dashboard-workers start


# Install mcollective server *AND CLIENT* (Client is the one that communicates with all the other nodes)
apt-get -qq -y install openjdk-6-jre

cd /opt
wget --no-verbose http://archive.apache.org/dist/activemq/apache-activemq/5.8.0/apache-activemq-5.8.0-bin.tar.gz
tar -zxf apache-activemq-5.8.0-bin.tar.gz
mv apache-activemq-5.8.0 activemq

cat > activemq/conf/activemq.xml <<EOF
<beans
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:amq="http://activemq.apache.org/schema/core"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
  http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd
  http://activemq.apache.org/camel/schema/spring http://activemq.apache.org/camel/schema/spring/camel-spring.xsd">

    <bean class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
        <property name="locations">
            <value>file:\${activemq.base}/conf/credentials.properties</value>
        </property>
    </bean>

    <!--
      For more information about what MCollective requires in this file,
      see http://docs.puppetlabs.com/mcollective/deploy/middleware/activemq.html
    -->

    <!--
      WARNING: The elements that are direct children of <broker> MUST BE IN
      ALPHABETICAL ORDER. This is fixed in ActiveMQ 5.6.0, but affects
      previous versions back to 5.4.
      https://issues.apache.org/jira/browse/AMQ-3570
    -->
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" useJmx="true" schedulePeriodForDestinationPurge="60000">
        <!--
          MCollective generally expects producer flow control to be turned off.
          It will also generate a limitless number of single-use reply queues,
          which should be garbage-collected after about five minutes to conserve
          memory.

          For more information, see:
          http://activemq.apache.org/producer-flow-control.html
        -->
        <destinationPolicy>
          <policyMap>
            <policyEntries>
              <policyEntry topic=">" producerFlowControl="false"/>
              <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
            </policyEntries>
          </policyMap>
        </destinationPolicy>

        <managementContext>
            <managementContext createConnector="false"/>
        </managementContext>

        <plugins>
          <statisticsBrokerPlugin/>

          <!--
            This configures the users and groups used by this broker. Groups
            are referenced below, in the write/read/admin attributes
            of each authorizationEntry element.
          -->
          <simpleAuthenticationPlugin>
            <users>
              <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
              <authenticationUser username="admin" password="secret" groups="mcollective,admins,everyone"/>
            </users>
          </simpleAuthenticationPlugin>

          <!--
            Configure which users are allowed to read and write where. Permissions
            are organized by group; groups are configured above, in the
            authentication plugin.

            With the rules below, both servers and admin users belong to group
            mcollective, which can both issue and respond to commands. For an
            example that splits permissions and doesn't allow servers to issue
            commands, see:
            http://docs.puppetlabs.com/mcollective/deploy/middleware/activemq.html#detailed-restrictions
          -->
          <authorizationPlugin>
            <map>
              <authorizationMap>
                <authorizationEntries>
                  <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <authorizationEntry queue="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <!--
                    The advisory topics are part of ActiveMQ, and all users need access to them.
                    The "everyone" group is not special; you need to ensure every user is a member.
                  -->
                  <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
                </authorizationEntries>
              </authorizationMap>
            </map>
          </authorizationPlugin>
        </plugins>

        <!--
          The systemUsage controls the maximum amount of space the broker will
          use for messages. For more information, see:
          http://docs.puppetlabs.com/mcollective/deploy/middleware/activemq.html#memory-and-temp-usage-for-messages-systemusage
        -->
        <systemUsage>
            <systemUsage>
                <memoryUsage>
                    <memoryUsage limit="20 mb"/>
                </memoryUsage>
                <storeUsage>
                    <storeUsage limit="1 gb" name="foo"/>
                </storeUsage>
                <tempUsage>
                    <tempUsage limit="100 mb"/>
                </tempUsage>
            </systemUsage>
        </systemUsage>

        <!--
          The transport connectors allow ActiveMQ to listen for connections over
          a given protocol. MCollective uses Stomp, and other ActiveMQ brokers
          use OpenWire. You'll need different URLs depending on whether you are
          using TLS. For more information, see:

          http://docs.puppetlabs.com/mcollective/deploy/middleware/activemq.html#transport-connectors
        -->
        <transportConnectors>
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
            <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>
        </transportConnectors>
    </broker>

    <!--
      Enable web consoles, REST and Ajax APIs and demos.
      It also includes Camel (with its web console); see \${ACTIVEMQ_HOME}/conf/camel.xml for more info.

      See \${ACTIVEMQ_HOME}/conf/jetty.xml for more details.
    -->
    <import resource="jetty.xml"/>
</beans>
EOF

ln -s /opt/activemq/bin/linux-x86-64/activemq /etc/init.d/activemq


# Open up the puppet devel repos
sed -i 's/# deb /deb /g' /etc/apt/sources.list.d/puppetlabs.list
apt-get -qq update

# mcollective packages
gem install stomp --quiet
apt-get -qq -y install mcollective mcollective-client

# mcollective plugins
apt-get -qq -y install mcollective-puppet-client mcollective-package-client mcollective-service-client

cat > /etc/mcollective/client.cfg <<EOF
# main config
libdir = /usr/share/mcollective/plugins
logfile = /dev/null
loglevel = error

# connector plugin config
connector = activemq
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = puppet
plugin.activemq.pool.1.port = 61613
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = marionette

# security plugin config
securityprovider = psk
plugin.psk = abcdefghj
EOF

cat > /etc/mcollective/server.cfg <<EOF
# main config
libdir = /usr/share/mcollective/plugins
logfile = /var/log/mcollective.log
daemonize = 1
loglevel = info

# connector plugin config
connector = activemq
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = puppet
plugin.activemq.pool.1.port = 61613
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = marionette

# facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml

# security plugin config
securityprovider = psk
plugin.psk = abcdefghj
EOF

service activemq start
service mcollective restart

echo "Puppet master setup complete. Hilary puppet config is found in /etc/puppet/puppet-hilary"
