#! /bin/bash

BACKUP_DIR="/mnt/backup"
export $(grep -v '^#' .env | xargs)

# Backup databases
echo "Backing up databases"
echo "---Influxdb"
# Influxdb
sudo docker exec -it influxdb influx backup --bucket homeassistant /var/lib/influxdb/backup
sudo docker cp influxdb:/var/lib/influxdb/backup influxdb_backup
sudo tar -czf $BACKUP_DIR/ha_influxdb.tar.gz influxdb_backup
sudo rm -rf influxdb_backup
sudo docker exec -it influxdb rm -rf /var/lib/influxdb/backup

# Mariadb
echo "---Mariadb"
sudo docker exec -it mariadb mariadb-dump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > mariadb_backup.sql
sudo tar -czf $BACKUP_DIR/ha_mariadb.tar.gz mariadb_backup.sql
sudo rm -rf mariadb_backup.sql

# unset environment vars from an .env file
unset $(grep -v '^#' .env | awk 'BEGIN { FS = "=" } ; { print $1 }')