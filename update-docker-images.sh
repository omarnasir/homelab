#! /bin/bash
mapfile -t STACKS < STACKS.txt

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)

# Run docker-compose
for app in "${STACKS[@]}"
do
     docker compose -f "$app/docker-compose.yml" pull
done

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')
