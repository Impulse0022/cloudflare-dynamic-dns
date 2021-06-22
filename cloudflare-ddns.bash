#!/bin/bash

# This script updates an existing DNS A record hosted by Cloudflare with your current IP address 
# via the Cloudflare API v4.
#
# ================================================================================================
#

function usage {
  echo "Usage: cloudflare-ddns.bash [-z Zone] [-r DNS Record] [-t Token] [-p Proxy (true/false)]"
}

# Get Command Line Options
while getopts "z:r:t:p:" OPTS
do
  case $OPTS in
    z )
    # Cloudflare Zone is the zone that holds the record
    ZONE=$OPTARG
    ;;
    
    r )
    # DNS Record is the A record that will be updated
    DNS_RECORD=$OPTARG
    ;;

    t )
    # Cloudflare API Token. Token must have Edit Zone DNS authority.
    CLOUDFLARE_API_TOKEN=$OPTARG
    ;;

    p )
    # Specifies if Cloudflare proxy should be used when updating the DNS A record
    PROXY=$OPTARG
    ;;

    \? )
    echo "Invalid Option: -$OPTARG"
    usage
    exit 1
    ;;

    : )
    echo "Missing Option Arugment: -$OPTARG"
    usage
    exit 1
    ;;
  esac
done

if [ -z "$ZONE" ] || [ -z "$DNS_RECORD" ] || [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$PROXY" ]; then
  usage
  exit 1
fi

# Get the current external IP address
CURRENT_IP=$(curl -s -X GET https://checkip.amazonaws.com)

echo "Current IP address is $CURRENT_IP"

# Get the Zone ID for the specified Zone
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE&status=active" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

echo "Zone ID for $ZONE is $ZONE_ID"

# Get the DNS Content for the existing DNS Record
DNS_CONTENT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNS_RECORD" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .content')

echo "DNS Record Content for $DNS_RECORD is $DNS_CONTENT"

# Get the DNS Proxied state for the existing DNS Record
DNS_PROXIED=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNS_RECORD" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .proxied')

echo "DNS Proxied state for $DNS_RECORD is $DNS_PROXIED"

if [ "$CURRENT_IP" == "$DNS_CONTENT" ] && [ "$PROXY" == "$DNS_PROXIED" ]; then
  echo "$DNS_RECORD is currently $DNS_CONTENT and matches current IP of: $CURRENT_IP. Record was not updated."
  exit 0
fi

# Get the DNS Record ID
DNS_RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DNS_RECORD" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

echo "DNS Record ID for $DNS_RECORD is $DNS_RECORD_ID"

# Update the specified DNS Record ID
echo "Updating DNS Record ID: $DNS_RECORD_ID with $CURRENT_IP"

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$DNS_RECORD\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":$PROXY}" | jq
