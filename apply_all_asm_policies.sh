#! /bin/bash

# This script increments through ASM policies and re-applies them, in response to bug referenced by K83093212
# Written on a Friday afternoon by Jesse Darrone (j.darrone@f5.com)...please excuse any bugs.

# Note that the configuration values below could easily be replaced by $1, $2, $3, $4 respectively in order to take these
# parameters from the command line instead.  Ideally you'd also want some basic error handling were you to take that approach.

# Login Credentials
user="username"
password="password"

# FQDN to management interface
host="hostname.domain.tld"

# How many seconds between requests?
delay=1

#----------------------------- End User Configurable Portion ------------------------------------#

header="Content-Type: application/json"
policyPath="https://$host/mgmt/tm/asm/policies/"
applyPolicyPath="https://$host/mgmt/tm/asm/tasks/apply-policy/"
curlGet="curl -sk -u $user:$password -X GET"
curlPost="curl -sk -u $user:$password -X POST -H $header"

dependencies="\
curl \
cut \
echo \
jq"

# Ensure required utilities are available before continuing
for d in $dependencies; do
  hash $d 2>/dev/null || { echo >&2 "$d required but not installed or not in \$PATH.  Hard abort."; exit 1; }
done

# Function to generate json payload for post requests
generate_post_data()
{
  cat <<EOF
{
  "policyReference": {
    "link": "https://$host/mgmt/tm/asm/policies/$1"
  }
}
EOF
}

# Get the list of policies on the system
policies=`$curlGet $policyPath | jq '.items[] | .name + ";" + .id'`

# Increment through policies and re-apply each one
for i in $policies; do
  sleep $delay
  policyName=`echo ${i//\"} | cut -d \; -f1`
  policyId=`echo ${i//\"} | cut -d \; -f2`
  echo -en "\nRe-applying policy \"$policyName\" ($policyId)...\n "
  $curlPost -d "$(generate_post_data $policyId)" $applyPolicyPath
  echo -en "\n"
done
