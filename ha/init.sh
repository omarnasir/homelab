#! /bin/bash
# setup mariadb user permissions

# Get only MYSQL_SOCKET variable from .env
MYSQL_SOCKET=$(grep MYSQL_SOCKET .env | cut -d= -f2)
# Check if directory exists
[ ! -d $MYSQL_SOCKET ] && mkdir -p $MYSQL_SOCKET || chown -R $PUID:$PGID $MYSQL_SOCKET

# Configure data directory for mariadb
DATA_DIR_MARIADB="./data/mariadb"
# Check if directory exists
[ ! -d $DATA_DIR_MARIADB ] && mkdir -p $DATA_DIR_MARIADB || chown -R $PUID:$PGID $DATA_DIR_MARIADB
