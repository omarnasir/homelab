#! /bin/bash
mapfile -t APPS_CNAME < APPS_CNAME.txt
mapfile -t STACKS < STACKS.txt

# Add caddy to the end so it will have access to the networks of each stack
STACKS+=("caddy")

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
     cd $app
     # Run init.sh if it exists
     if [ -f init.sh ]; then
          source init.sh
     fi
     docker compose up -d
     cd ..
done

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')
