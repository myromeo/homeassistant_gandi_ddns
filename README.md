# Gandi Dynamic DNS Add-On for Home Assistant

This Home Assistant add-on checks and updates Gandi DNS records with your external IP every 5 minutes.

## Features
- Supports both root (@) and subdomains
- Publishes sensor data to an MQTT broker
- Checks and upodates your Gandi A Record every 5 minutes. 

## Installation
1. Get your Gandi API key (from https://account.gandi.net/). Click your username, Account Settings and create a Personal Access Token. Be sure to note this as you can not retrieve it once you've left the creating screen!
2. Install this add-on via the Home Assistant Add-on Store.
3. Enter your API key, domain, and subdomain in the add-on configuration.
4. If required, Enter the IP address, username and password of your MQTT broker in the add-on configuration.
5. Start the add-on. Your DNS will update automatically!

## Home Assistant MQTT Sensor

To use your MQTT sensor in your installation, add the following to your configuration.yaml file: 

```yaml
mqtt:
  binary_sensor:
    - name: "Gandi DNS"
      state_topic: "homeassistant/sensor/gandi_dns/state"
      value_template: "{{ value_json.status }}"
      payload_on: "connected"
      payload_off: "disconnected"
      device_class: connectivity
      json_attributes_topic: "homeassistant/sensor/gandi_dns/state"
      unique_id: "gandi_dns"
      icon: "mdi:earth"
```

This sensor will create a binary 'connectivity' sensor with the attributes External IP, DNS record IP and Full domain 
