ARG BUILD_FROM
FROM $BUILD_FROM

# Set environment variables
ENV LANG C.UTF-8

# Install required packages
RUN apk add --no-cache bash jq curl mosquitto-clients

# Copy scripts
COPY run.sh /run.sh
COPY gandi-dns-update.sh /usr/bin/gandi-dns-update.sh

# Set permissions
RUN chmod +x /run.sh /usr/bin/gandi-dns-update.sh

# Run script as the main process
CMD [ "/run.sh" ]
