#! /bin/bash
mapfile -t APPS_CNAME < APPS_CNAME.txt
mapfile -t STACKS < STACKS.txt

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)

# ----------------- #
# PiHole DNS Config #
# Write the IP of the host to the custom.list file for pihole DNS resolution
echo "$HOST_IP $HOME_DOMAIN"  > ./pihole/config/etc-pihole/custom.list
# Write CNAME for pihole to resolve to the host. Define your apps here that you wish
# to be accessible via hostname on your local network.
> ./pihole/config/etc-dnsmasq.d/05-pihole-custom-cname.conf

for app in "${APPS_CNAME[@]}"
do
     echo "cname=$app.$HOME_DOMAIN,$HOME_DOMAIN" >> \
     ./pihole/config/etc-dnsmasq.d/05-pihole-custom-cname.conf
done
# ----------------- #

# Run docker-compose
for app in "${STACKS[@]}"
do
     docker compose -f "$app/docker-compose.yml" up -d
done

# Install Reverse proxy so all dependent networks have access to the reverse proxy
docker compose -f caddy/docker-compose.yml up -d

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')
