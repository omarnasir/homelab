#! /bin/bash
# Purpose: Restore important files from SD Card

mapfile -t STACKS < STACKS.txt
STACKS+=("caddy")

# Restore stack helper functions
restore_budget() {
    cd budget
    mkdir -p data/actual
    mkdir -p data/ihatemoney
    # Actual
    echo "---budget: Actual"
    tar -xzf actual.tar.gz -C data/actual
    # ihatemoney
    echo "---budget: ihatemoney"
    tar -xzf ihatemoney.tar.gz -C data/ihatemoney
    cd ..
}

restore_ha() {
    cd ha
    mkdir -p data/influxdb
    mkdir -p data/mariadb
    # Influxdb
    echo "---ha: Influxdb"
    tar -xzf influxdb.tar.gz -C data/influxdb
    # Mariadb
    echo "---ha: Mariadb"
    tar -xzf mariadb.tar.gz -C data/mariadb
    cd ..
}

restore_stack_config() {
    echo "Restoring: $1"
    # Restore config directory by untarring it
    cd $1
    tar -xzf config.tar.gz
    rm config.tar.gz
    cd ..
    echo "---$1: Restored: config"
}

for stack in "${STACKS[@]}"
do
    if [ $stack == "budget" ]; then
        restore_stack_config $stack
        restore_budget
        echo "---$stack: Restored: data"
    elif [ $stack == "ha" ]; then
        restore_stack_config $stack
        restore_ha
        echo "---$stack: Restored: data"
    else
        restore_stack_config $stack
    fi
done

echo "Done!"
