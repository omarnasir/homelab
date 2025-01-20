#! /bin/bash
# Import helper functions
source "scripts/config-parser.sh"

# Get arguments
arg_action=$1
arg_stack=$2

if [ -z "$arg_stack" ] || [ -z "$arg_action" ]; then
	echo "ERROR: Missing required arguments.
	
Usage: $ bash install-docker-apps.sh [stack] [action]
	
Args:
	[stack]: The stack to be installed. Accepted values: all | [stack_name]
	[action]: The action to be performed. Accepted values: install | update"
	exit 1
elif [ "$arg_action" != "install" ] && [ "$arg_action" != "update" ]; then
	echo "ERROR: Invalid action"
	exit 1
fi

# Parse the stacks
parse_config_file $arg_stack
process_stacks $arg_stack

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)

install() {
	# ----------------- #
	# PiHole DNS Config #
	# Write the IP of the host to the custom.list file for pihole DNS resolution
	echo "$HOST_IP $HOME_DOMAIN"  > pihole/config/etc-pihole/custom.list
	echo "$HOST_IP $DOMAIN"  > pihole/config/etc-pihole/custom.list
	# Write CNAME for pihole to resolve to the host. Define your apps here that you wish
	# to be accessible via hostname on your local network.
	path_to_cname="pihole/config/etc-dnsmasq.d/05-pihole-custom-cname.conf"
	[ -z path_to_cname ] && touch $path_to_cname
	# Add the cnames to the pihole custom-cname file
	flag_cname_changed=0
	for ((index = 0; index < ${#CNAMES[@]}; index++));
	do 
		cname=${CNAMES[$index]}
		# The cname depends on the type defined in the config file.
		# If the type is "internal", the cname will use $HOME_DOMAIN, else use $DOMAIN for "external"
		type=${TYPES[$index]}
		domain=$([ "$type" == "internal" ] && echo "$HOME_DOMAIN" || echo "$DOMAIN")
		# Search if the cname is not in the pihole custom-cname file
		if ! grep -q "$cname.$domain" "$path_to_cname"; then
			echo "cname=$cname.$domain,$domain" >> "$path_to_cname"
			flag_cname_changed=1
		fi
	done
	# ----------------- #

	# Add caddy to the end so it will have access to the networks of each stack
	STACKS+=("caddy")

	# Run docker-compose
	for app in "${STACKS[@]}"
	do
		cd $app
		# Run init.sh if it exists
		[ -f init.sh ] && source init.sh
		docker compose up -d
		cd ..
	done

	# Restart pihole if it is running, the cname flag is set, and the
	# pihole was not included in the stacks to be run
	if [ -n "$(docker ps -q -f name=pihole)" ] && [ $flag_cname_changed -eq 1 ]; then
		docker exec -it pihole pihole restartdns
		echo "INFO: Restarting pihole DNS resolver"
		docker restart pihole
	fi

	# Finally reload CaddyFile if it is running and the cname flag is set
	if [ -n "$(docker ps -q -f name=caddy)" ] && [ $flag_cname_changed -eq 1 ]; then
		echo "INFO: Reloading CaddyFile"
		docker exec -w /etc/caddy caddy caddy reload
	fi
}

update() {
	# Run docker-compose
	for app in "${STACKS[@]}"
	do
		cd $app
		docker compose pull
		docker compose up -d
		# Remove dangling images
		docker image prune -f
		cd ..
	done
}

if [ "$arg_action" == "install" ]; then
	install
elif [ "$arg_action" == "update" ]; then
	update
fi

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')
