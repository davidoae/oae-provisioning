#!/bin/bash

echo '# Allow for very large messages to be logged. This needs to go before any network related
# configuration gets set
$MaxMessageSize 32k

#################
#### MODULES ####
#################

module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support
#module(load="immark")  # provides --MARK-- message capability

# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")

# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

###########################
#### GLOBAL DIRECTIVES ####
###########################

#
# Use traditional timestamp format.
# To enable high precision timestamps, comment out the following line.
#
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# Filter duplicated messages
$RepeatedMsgReduction on

#
# Set the default permissions for all log files.
#
$FileOwner syslog
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog

#
# Where to place spool and state files
#
$WorkDirectory /var/spool/rsyslog

#
# Include all config files in /etc/rsyslog.d/
#
$IncludeConfig /etc/rsyslog.d/*.conf
' > /etc/rsyslog.conf

echo > /etc/rsyslog.d/50-default.conf '
#### TEMPLATES ####

$template DynAuth,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/auth-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal0,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local0-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal1,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local1-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal2,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local2-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal3,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local3-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal4,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local4-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal5,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local5-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynLocal6,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/local6-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynMail,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/mail-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynOther,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/other-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynKern,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/kern-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynBoot,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/boot-%$YEAR%-%$MONTH%-%$DAY%.log"
$template DynCron,"/var/log/rsyslog/%HOSTNAME%-%fromhost-ip%/cron-%$YEAR%-%$MONTH%-%$DAY%.log"

#### RULES ####

kern.*              ?DynKern
authpriv.*;auth.*   ?DynAuth
mail.*              ?DynMail
cron.*              ?DynCron
local0.*            ?DynLocal0
local1.*            ?DynLocal1
local2.*            ?DynLocal2
local3.*            ?DynLocal3
local4.*            ?DynLocal4
local5.*            ?DynLocal5
local6.*            ?DynLocal6
local7.*            ?DynBoot

# All other facilities go to the Other log
ftp.*;lpr.*;news.*;syslog.*;user.*;uucp.*   ?DynOther

# All logged in users get emergency messages
*.emerg;*.alert;*.crit :omusrmsg:*
'

systemctl restart rsyslog.service

echo "syslog setup done"

