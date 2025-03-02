#!/usr/bin/with-contenv bash
# Home Assistant Gandi Dynamic DNS Add-on Startup Script

CONFIG_PATH=/data/options.json

# Read options from Home Assistant
API_TOKEN=$(jq --raw-output '.api_token' $CONFIG_PATH)
DOMAIN=$(jq --raw-output '.domain' $CONFIG_PATH)
SUBDOMAIN=$(jq --raw-output '.subdomain' $CONFIG_PATH)
TTL=$(jq --raw-output '.ttl' $CONFIG_PATH)
MQTT_SERVER=$(jq --raw-output '.mqtt_server' $CONFIG_PATH | sed 's|mqtt://|tcp://|')
MQTT_USERNAME=$(jq --raw-output '.mqtt_username' $CONFIG_PATH)
MQTT_PASSWORD=$(jq --raw-output '.mqtt_password' $CONFIG_PATH)

# Ensure MQTT server uses tcp:// format
#if [[ "$MQTT_SERVER" != tcp://* ]]; then
#    MQTT_SERVER="tcp://$MQTT_SERVER"
#fi

FULL_DOMAIN="$SUBDOMAIN.$DOMAIN"
if [ "$SUBDOMAIN" = "@" ]; then
    FULL_DOMAIN="$DOMAIN"
fi

echo "[INFO] $(date) Starting Gandi Dynamic DNS Add-on..."
echo "[INFO] $(date) Domain: $DOMAIN"
echo "[INFO] $(date) Subdomain: $SUBDOMAIN"
echo "[INFO] $(date) Full Address: $FULL_DOMAIN"
echo "[INFO] $(date) TTL: $TTL"
echo "[INFO] $(date) MQTT Server: $MQTT_SERVER"

# Run the script in an infinite loop to prevent container exit
while true; do
    echo "[INFO] $(date) Checking external IP..."
    
    # Get current external IP
    EXTERNAL_IP=$(curl -s https://api64.ipify.org)

    # Get current DNS record IP
    echo "[INFO] $(date) Checking DNS record IP..."
    DNS_RESPONSE=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        "https://api.gandi.net/v5/livedns/domains/$DOMAIN/records/$SUBDOMAIN/A")

    DNS_RECORD_IP=$(echo "$DNS_RESPONSE" | jq -r '.rrset_values[0] // "unknown"')

    if [ "$DNS_RECORD_IP" = "unknown" ] || [ -z "$DNS_RECORD_IP" ]; then
        echo "[WARNING] $(date) Failed to retrieve DNS record IP. Full response from Gandi API:"
        echo "$DNS_RESPONSE"
        DNS_RECORD_IP="not_set"
    fi

    # Only update DNS if external IP has changed
    if [ "$EXTERNAL_IP" = "$DNS_RECORD_IP" ]; then
        echo "[INFO] $(date) DNS Record is up to date. No update needed."
    else
        echo "[INFO] $(date) IP changed from $DNS_RECORD_IP to $EXTERNAL_IP. Updating DNS..."
        /usr/bin/gandi-dns-update.sh "$API_TOKEN" "$DOMAIN" "$SUBDOMAIN" "$TTL"
    fi

    # Publish sensor data via MQTT
    if command -v mosquitto_pub > /dev/null; then
        mosquitto_pub -h "$MQTT_SERVER" -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -t "homeassistant/sensor/gandi_dns/config" -m '{
            "name": "Gandi DNS",
            "state_topic": "homeassistant/sensor/gandi_dns/state",
            "value_template": "{{ value_json.status }}",
	    "payload_on": "connected",
      	    "payload_off": "disconnected",
            "device_class": "connectivity",
            "json_attributes_topic": "homeassistant/sensor/gandi_dns/state",
            "unique_id": "gandi_dns",
            "icon": "mdi:earth"
        }'

        mosquitto_pub -h "$MQTT_SERVER" -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -t "homeassistant/sensor/gandi_dns/state" -m "{
            \"status\": \"$( [ "$EXTERNAL_IP" = "$DNS_RECORD_IP" ] && echo "connected" || echo "disconnected" )\",
            \"external_ip\": \"$EXTERNAL_IP\",
            \"dns_record_ip\": \"$DNS_RECORD_IP\",
            \"full_domain\": \"$FULL_DOMAIN\"
        }"
    else
        echo "[WARNING] $(date) MQTT client not found, skipping sensor update."
    fi

    sleep 300
done
