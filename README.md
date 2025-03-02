# Gandi Dynamic DNS Add-On for Home Assistant

This Home Assistant add-on checks and updates Gandi DNS records with your external IP every 5 minutes.

## Features
- Supports both root (@) and subdomains
- Works on all architectures supported by Home Assistant OS
- Compatible with Home Assistant templates for automation
- Publishes sensor data to an MQTT broker

## Installation
1. Get your Gandi API key (from https://account.gandi.net/).
2. Install this add-on via the Home Assistant Add-on Store.
3. Enter your API key, domain, and subdomain in the add-on settings.
4. Enter the IP address, username and password of your MQTT broker
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