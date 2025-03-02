#!/bin/bash

API_TOKEN="$1"
DOMAIN="$2"
SUBDOMAIN="$3"
TTL="$4"

GET_IP_CMD="curl -s https://api64.ipify.org"
CURRENT_IP=$($GET_IP_CMD)

if [ -z "$CURRENT_IP" ]; then
    echo "$(date): Failed to fetch external IP"
    exit 1
fi

DNS_RECORD=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
    "https://api.gandi.net/v5/livedns/domains/$DOMAIN/records/$SUBDOMAIN/A" | jq -r '.data[0].rrset_values[0]')

if [ "$CURRENT_IP" != "$DNS_RECORD" ]; then
    echo "$(date): IP changed from $DNS_RECORD to $CURRENT_IP. Updating DNS..."
    curl -s -X PUT -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"rrset_values\":[\"$CURRENT_IP\"], \"rrset_ttl\":$TTL}" \
        "https://api.gandi.net/v5/livedns/domains/$DOMAIN/records/$SUBDOMAIN/A"

    echo "$(date): DNS A record updated to $CURRENT_IP with TTL $TTL seconds."
else
    echo "$(date): IP unchanged at $CURRENT_IP. TTL: $TTL seconds."
fi
