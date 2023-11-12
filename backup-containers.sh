#! /bin/bash
# Purpose: Backup important files to SD Card
# For each stack listed in STACKS.txt, backup the .env, docker-compose.yml, and the
# directory stack/config to the SD Card.
# Use rsync to backup the data directory to the SD Card.

mapfile -t STACKS < STACKS.txt
BACKUP_DIR="/mnt/backup"

# Write backup date to file
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
echo $DATE > $BACKUP_DIR/backup_date.txt

for STACK in "${STACKS[@]}"
do
    echo "Backing up $STACK"
    cp $STACK/.env $BACKUP_DIR/$STACK.env
    cp $STACK/docker-compose.yml $BACKUP_DIR/$STACK.docker-compose.yml
    tar -czf $BACKUP_DIR/$STACK.config.tar.gz $STACK/config/.
    echo "--- Done backing up $STACK"
done
