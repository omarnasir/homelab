# 1. Pre-requisites
Before install docker apps, the following environment variables must be set in the root .env file as well as the .env file in the required app directory. This is for security reasons, if the sensitive variables are set in the root directory, during docker compose session all containers will have access to these, meaning if a container is compromised it can leak these variables. 

If an app is not mentioned below, it does not require any environment variables to be set, or it will use the default values set in the root .env file.

## 1.1. Required .env variables
These are general examples, and should be modified freely.
```ini
-> ./.env
# General
TZ=Europe/London
PUID=1000
PGID=1000
# CADDY
REVERSE_PROXY_NETWORK=caddy_network
HOME_DOMAIN=homelab.home
HOST_IP=192.168.1.2
HOST_GATEWAY=192.168.1.1
HOST_SUBNET=192.168.1.0/24

-> ./pihole/.env
# Pi-hole
PIHOLE_WEBPASSWORD="mypassword"

-> ./plex/.env
# Plex
PLEX_CLAIM="claim_plex"
PLEX_ALLOWED_NETWORKS="192.168.1.0/24"
```

## 1.2. Sanity Check
**`install-docker-apps.sh`**: This script is used to install all the apps.

***Declared Variables***:

* `APPS_TO_COMPOSE`: There is a list of apps to be installed declared in the beginning of the script. This should contain all the apps that you want to install. 
* `APPS_FOR_CNAME_RESOLUTION`: This is a list of apps that we want to access by their domain name. This is used to create a CNAME record in the pihole container. Important: Caddy must not be included in this list. This stack uses Homarr for homepage dashboard, which must be accessible at `http://{$HOME_DOMAIN}` Since that is already handled by caddy, we do not need to create a CNAME record for it.

---
# 2. Installation
Once the environment variables are set, you can install the apps by running the following command:

`./install-docker-apps.sh`

If you feel that you do not need to install all the apps, you can individually install apps by using the docker-compose command:

`docker-compose -f ./app_name/docker-compose.yml up -d`

---
# 3. Adding New Apps
Checklist:
- [ ] Create a new directory for the app at `./{app_name}`
- [ ] Create a `docker-compose.yml` file in the new directory and ensure it uses the correct caddy network if it is exposed to the internet via web proxy.
- [ ] The volumes must be split into `config` and `data` volumes. This is for backup purposes ***<span style="color: red;">!TODO: Add backup script</span>***
- [ ] The `docker-compose.yml` file should use the `.env` file in the same directory for environment variables.
- [ ] Add app to `APPS_TO_COMPOSE` in `install-docker-apps.sh` 
- [ ] Add app to `APPS_FOR_CNAME_RESOLUTION` in `install-docker-apps.sh` if it is exposed to the local network by CNAME resolution.