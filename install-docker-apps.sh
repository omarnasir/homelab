#! /bin/bash

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Create docker network
docker network create "$REVERSE_PROXY_NETWORK" --driver=bridge

# ----------------- #
# PiHole DNS Config #
# Write the IP of the host to the custom.list file for pihole DNS resolution
echo "$HOST_IP $HOME_DOMAIN"  > ./pihole/config/etc-pihole/custom.list
# Write CNAME for pihole to resolve to the host. Define your apps here that you wish
# to be accessible via hostname on your local network.
> ./pihole/config/etc-dnsmasq.d/05-pihole-custom-cname.conf

APPS=( "homeassistant" "pihole" "plex" )
for app in "${APPS[@]}"
do
     echo "cname=$app.$HOME_DOMAIN,$HOME_DOMAIN" >> \
     ./pihole/config/etc-dnsmasq.d/05-pihole-custom-cname.conf
done
# ----------------- #

# Run docker-compose
docker-compose up -d

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')
