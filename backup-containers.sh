#! /bin/bash
# Purpose: Backup important files to SD Card
# For each stack listed in STACKS.txt, backup the .env, docker-compose.yml, and the
# directory stack/config to the SD Card.

# Declare variables
mapfile -t STACKS < STACKS.txt
STACKS+=("caddy")
BACKUP_ROOT="/mnt/backup"

# Declare stack helper backup functions
backup_budget() {
    # Actual
    cd budget/data/actual
    touch actual.tar.gz
    tar --exclude=actual.tar.gz -czf actual.tar.gz .
    mv actual.tar.gz $BACKUP_ROOT/budget/actual.tar.gz
    cd ../../..

    # ihatemoney
    cd budget/data/ihatemoney
    touch ihatemoney.tar.gz
    tar --exclude=ihatemoney.tar.gz -czf ihatemoney.tar.gz .
    mv ihatemoney.tar.gz $BACKUP_ROOT/budget/ihatemoney.tar.gz
    cd ../../..

    echo "---budget: Backed up: data"

}

backup_ha() {
    cd ha/data/
    # Influxdb
    touch influxdb.tar.gz
    tar --exclude=influxdb.tar.gz -czf influxdb.tar.gz influxdb/.
    mv influxdb.tar.gz $BACKUP_ROOT/ha/influxdb.tar.gz

    # Mariadb
    touch mariadb.tar.gz
    tar --exclude=mariadb.tar.gz -czf mariadb.tar.gz mariadb/.
    mv mariadb.tar.gz $BACKUP_ROOT/ha/mariadb.tar.gz
    cd ../..

    echo "---ha: Backed up: data"
}

# General function to backup stack files, excluding the config and data directory
# first argument must be the stack name
backup_stack_config() {
    echo "Backing up: $1"
    cd $1
    # Create backup directory for stack
    BACKUP_DIR=$BACKUP_ROOT/$1
    mkdir -p $BACKUP_DIR
    # Backup .env, docker-compose.yml and init.sh
    files=(".env" "docker-compose.yml" "init.sh")
    for file in "${files[@]}"; do
        if [ -f $file ]; then
            cp $file $BACKUP_DIR/$file
        fi
    done
    # Backup config directory by tarring it
    touch config.tar.gz
    tar --exclude=config.tar.gz -czf config.tar.gz config/.
    mv config.tar.gz $BACKUP_DIR/config.tar.gz
    cd ..
    echo "---$1: Backed up: config"
}

# Backup each stack, with stack specific backup commands
for stack in "${STACKS[@]}"; do
    if [ $stack == "budget" ]; then
        backup_stack_config $stack
        backup_budget
    elif [ $stack == "ha" ]; then
        backup_stack_config $stack
        backup_ha
    else
        backup_stack_config $stack
    fi
done

# Write backup date to file
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
echo $DATE > $BACKUP_ROOT/backup_date.txt

# Unset STACKS variable
unset STACKS && unset DATE && unset BACKUP_ROOT && unset BACKUP_DIR
echo "Done backing up all stacks"