# Homelab Stack

**Table of Contents**
- [Homelab Stack](#homelab-stack)
- [Section 1: Ubuntu Server](#section-1-ubuntu-server)
  - [1.1. First Run](#11-first-run)
  - [1.2. Install Docker](#12-install-docker)
  - [1.3. Slow Boot Times](#13-slow-boot-times)
  - [1.4. DNS Resolution](#14-dns-resolution)
  - [1.5. SSH Hardening](#15-ssh-hardening)
- [Section 2: Docker Apps](#section-2-docker-apps)
  - [2.1. Configure Docker Install Scripts](#21-configure-docker-install-scripts)
    - [2.1.1. Required .env variables](#211-required-env-variables)
    - [2.1.2. Sanity Check](#212-sanity-check)
  - [2.2. Install Docker Apps](#22-install-docker-apps)
  - [2.3. Updating Docker Apps](#23-updating-docker-apps)
  - [2.4. Adding New Apps](#24-adding-new-apps)
- [Section 3. Backup Scripts](#section-3-backup-scripts)
  - [3.1. Backup Using External Storage](#31-backup-using-external-storage)
  - [3.2. Backup Using same Host](#32-backup-using-same-host)
# Section 1: Ubuntu Server

This section assumes that you have already installed Ubuntu Server 22.04 on your machine and have SSH access to it. 

## 1.1. First Run
After installing Ubuntu Server, the first thing you should do is update the system and install the required packages. 
```bash
$ sudo apt update && sudo apt upgrade -y
$ sudo apt install -y git curl nslookup traceroute
```
---
> **_NOTE:_** Make sure you have a wired connection to the host machine before doing this.

Next, disable WiFi and Bluetooth if you are not planning to use them. This is to reduce the boot time of the system. 
```bash
$ sudo systemctl disable wpa_supplicant.service
$ sudo systemctl disable bluetooth.service
```
---
## 1.2. Install Docker

Docker installation details can be found here at https://docs.docker.com/engine/install/ubuntu/. The following is a summary of the steps required to install docker on Ubuntu 22.04:

* Uninstall old versions.
* Set up Docker apt repository.
* Install latest version of Docker Engine and containerd. Make sure it is also contains the latest version of docker-compose.
* Add user to docker group.
    ```bash
    $ sudo usermod -aG docker $USER
    ```
* Reboot the system.

## 1.3. Slow Boot Times
If you are using the ubuntu server 22.04 LTS on a RPI 4 and have just recently installed docker, chances are the next boot time might take very long. This happens because the **systemd-networkd-wait-online.service** is waiting for the network to be ready before continuing. This is a problem because the docker daemon is not ready yet, and the service will time out.

First check your boot time using critical chain:
```bash
$ systemd-analyze critical-chain
```

If the boot times are long, you should see something like this:
```bash
The time when unit became active or started is printed after the "@" character.
The time the unit took to start is printed after the "+" character.

graphical.target @2min 1.464s
```

2 minute boot time is unacceptable. To fix this, we need to instruct the **systemd-networkd-wait-online.service** to wait for the docker daemon to be ready. The contents of the override file can be found at `{root}/ubuntu_server/override.conf`. Replace these contents at the follwing directory:
    
```bash
$ sudo nano /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
```

## 1.4. DNS Resolution
If you are planning to use pihole as a DNS server, you will need to disable the systemd-resolved service. This is because the systemd-resolved service will listen on port 53, which is the default port for DNS. This will cause a conflict with pihole, which will also try to listen on port 53. The PiHole documentation has a good workaround that does not require disabling the systemd-resolved service. The workaround can be found here: https://github.com/pi-hole/docker-pi-hole#installing-on-ubuntu-or-fedora.

In newer versions of Ubuntu (Tested with: 22.04 LTS), the network manager is an application called netplan. A copy of a functional netplan configuration can be found at `{root}/ubuntu_server/netplan-config.yaml`. There are a few things that must be taken care of:
* The network interface is `eth0` by default. If you are using a different interface, change it accordingly.
* The local-link is set to ipv4 only. If you are using ipv6, change it accordingly.
* The nameservers are set to `127.0.0.1, 192.168.1.2`. The first nameserver is the localhost, which is the pihole container. The second nameserver is the router, which is used as a fallback. This is to ensure internet connectivity is not lost during updates or if the pihole container is down. If your subnet settings are different, change it accordingly. You can also use a cloud provider's DNS server, such as Google's.

## 1.5. SSH Hardening
There is a good amount of information available online on SSH hardening, however the following basic steps will greatly improve security:
* Disable root login.
* Disable password authentication.
* Disable X11 forwarding if you are not planning to use a client like FileZilla.
* Allowed users on a specific subnet only.
* Change the default port.
* Set Maximum authentication attempts to 3.
# Section 2: Docker Apps

## 2.1. Configure Docker Install Scripts
Before installing docker apps, the following environment variables must be set in the root .env file as well as the .env file in the required app directory. This is for security reasons, if the sensitive variables are set in the root directory, during docker compose session all containers will have access to these, meaning if a container is compromised it can leak these variables. 

If an app is not mentioned below, it does not require any environment variables to be set, or it will use the default values set in the root .env file.

Multiple apps can be bundled together in a single docker-compose.yml file, called a stack. This is done to reduce the number of docker-compose files, and to reduce the number of docker networks.

### 2.1.1. Required .env variables
These are general examples, and should be modified freely. The PUID and PGID are the user and group IDs of the user that will be running the docker containers. This is to ensure that the docker containers have the correct permissions to access the mounted volumes, as well as ensure docker containers do not have root access. The PUID and PGID can be found by running the following command:

```bash
$ id
```

Example output:

```bash
uid=1000(user) gid=1000(user) groups=1000(user),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),116(lpadmin),126(sambashare),127(docker)
```

```ini
-> ./.env
# General
BACKUP_ROOT=/mnt/backup
TZ=Europe/London
PUID=1000
PGID=1000
# CADDY
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
```

### 2.1.2. Sanity Check
***Declared Variables***:

The configuration is defined in `config.ini`. The format is simple, with each section denoting the name of the stack. The name must correspond to the name of the directory. Each section must contain the following variables:
* `cnames`: A list of CNAMEs that will be used to access the app. This is used to modify the dnsmasq settings in the pihole container.
* `backup`: The subdirectories to be backed up. Each container must have a `config` and `data` subdirectory. The `config` subdirectory contains the configuration files, and the `data` subdirectory contains the data files. The backup script will create a tar archive of the subdirectories and store it in the backup directory. 
**Warning**: Do not include the data subdirectory for containers that handle large replaceable files, such as Jellyfin.

```ini
[stack_name]
cnames=app1,app2
backup=config,data
```

---
## 2.2. Install Docker Apps
Once the environment variables are set, you can install the apps by running the following command. The argument `stack` can be either `all` or the name of the stack. The `all` argument will install all the apps. 
```bash
$ bash manager.sh install all
```

If you feel that you do not need to install all the apps, you can individually install apps by using the docker-compose command. Make sure the required .env variables are set. The `stack` argument will install the apps in the stack.
```bash
$ bash manager.sh install [stack]
```

## 2.3. Updating Docker Apps
To update all the apps, run the following command:
```bash
$ bash manager.sh update all
```

or to update a specific stack:
```bash
$ bash manager.sh update [stack]
```

---
## 2.4. Adding New Apps
Checklist:
- [ ] Create a new directory for the app at `./{app_name}`
- [ ] Create a `docker-compose.yml` file in the new directory and ensure it uses the correct caddy network if it is exposed to the internet via web proxy.
- [ ] The volumes must be split into `config` and `data` volumes. This is for backup purposes.
- [ ] The `docker-compose.yml` file should use the `.env` file in the same directory for environment variables.
- [ ] Add the app to `config.ini` with the correct CNAMEs and backup directories.

# Section 3. Backup Scripts

## 3.1. Backup Using External Storage

This guide assumes that an external storage is connected to the host machine for the sole purpose of maintaining external backups. The location of the external storage can be found by running the following command. Depending on the type of the storage, substitute the grep command accordingly. The example uses an MMC storage.
```bash
$ sudo fdisk -l | grep "mmc"
```

To mount the storage, run the following command. Make sure the mount point exists.
```bash
$ sudo mkdir /mnt/backup
$ sudo mount /dev/mmcblk0p2 /mnt/backup
```

Update the `BACKUP_ROOT` variable in `.env` file and set it to `/mnt/backup`. Run the following script to backup:
```bash
$ bash manager.sh backup [stack]
```

## 3.2. Backup Using same Host

If external storage is not available, the backup script can be used to backup to the same host. The backup script will create a tar archive of the backup directories and store it in the backup directory. The backup directory is set in the `.env` file. The backup script will also delete old backups to save space. The number of backups to keep is set in the `.env` file.

Example `.env` variable for backup:
```ini
BACKUP_ROOT=/home/user/backups
```

To backup, run the following command:
```bash
$ bash manager.sh backup [stack]
```

To restore, run the following command:
```bash 
$ bash manager.sh restore [stack]
```