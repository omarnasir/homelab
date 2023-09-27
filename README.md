# Pre-requisites
Before install docker apps, the following environment variables must be set in the root .env file as well as the .env file in the required app directory. If an app is not mentioned below, it does not require any environment variables to be set, or it will use the default values set in the root .env file.

## Required .env variables
```ini
-> ./.env
# General
TZ=
PUID=
PGID=
# CADDY
REVERSE_PROXY_NETWORK=
HOME_DOMAIN=
HOST_IP=
HOST_GATEWAY=
HOST_SUBNET=

-> ./pihole/.env
# Pi-hole
PIHOLE_WEBPASSWORD=

-> ./plex/.env
# Plex
PLEX_CLAIM=
```

# Verification
Verify that all your applications are imported in the docker-compose.yml file using the `include` attribute. If you are adding a new application, make sure to create its `{root}/new_app/.env` file and update the `README.md` file. 

Lastly, there is a list of apps to be installed declared in the beginning of the `install-docker-apps.sh` script. Update or modify it according to your needs.

# Installation

Once the environment variables are set, you can install the apps by running the following command:

`./install-docker-apps.sh`

If you feel that you do not need to install all the apps, you can individually install apps by using the docker-compose command:

`docker-compose -f ./app_name/docker-compose.yml up -d`