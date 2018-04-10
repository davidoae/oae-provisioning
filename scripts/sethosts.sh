#!/bin/bash
#
# generates hosts file suitable output for stated environment
# shame it's not built into the other tools at this time
#

### need to add a way to generate hosts file for each host
###  which is exactly what puppet was good for heh

tmpfile=/tmp/hostslist$$

environment="$1"
if [ -z "$environment" ]
then
  echo "Usage; sethosts.sh <environment>"
  exit 1
fi

slapchop -d staging >$tmpfile
if [ $? != 0 ]
then
  echo "slapchop failure"
  exit 2
fi

echo "# local hosts"
sed 's/[][)(]//g' $tmpfile | \
  egrep -v '(slapchop)|(I have not been bootstrapped)' | \
  awk '{ print $NF,$1 }'

echo "# remote hosts"
sed 's/[][)(]//g' $tmpfile | \
  egrep -v '(slapchop)|(I have not been bootstrapped)' | \
  awk -v e=$environment '{ print $(NF-1),$1"."e".oaeproject.org" }'

rm $tmpfile

