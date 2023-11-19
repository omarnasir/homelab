#! /bin/bash
# Purpose: Backup important files

# Import helper functions
source scripts/config-parser.sh

# Backup config or data directory for each stack. Run this function from the
# directory containing the stack.
# Args: $1: directory to backup
backup_stack_subdir() {
    local arg_dir=$1
    local arg_backup_dir=$2
    # Check if backup target dir exists
    [ ! -d $arg_dir ] && echo "WARNING: $arg_dir does not exist" && return 1
    # Backup config directory by tarring it
    touch $arg_dir.tar.gz
    tar --exclude=$arg_dir.tar.gz -czf $arg_dir.tar.gz $arg_dir
    mv $arg_dir.tar.gz $arg_backup_dir/$arg_dir.tar.gz
    echo "INFO: ---Backed up: $arg_dir"
}

restore_stack_subdir() {
    local arg_dir=$1
    # Check if target tar of the backup dir exists
    [ ! -f $arg_dir.tar.gz ] && echo "WARNING: $arg_dir.tar.gz does not exist" && return 1
    # Restore config directory by untarring it
    tar -xzf $arg_dir.tar.gz
    rm $arg_dir.tar.gz
    echo "INFO: ---Restored: $arg_dir"
}

get_docker_container_names() {
    # Search docker-compose.yml for all services and return their names. Service names are found
    # under the container_name key
    local services=$(grep -E "container_name" docker-compose.yml | cut -d: -f2 | tr -d ' ')
    echo $services
}

stop_docker_containers() {
    # Stop all docker containers for the current stack
    local services=$(get_docker_container_names)
    for service in $services; do
        docker stop $service
    done
}

start_docker_containers() {
    # Start all docker containers for the current stack
    local services=$(get_docker_container_names)
    for service in $services; do
        docker start $service
    done
}

# Set the stacks to be run
arg_action=$1
arg_stack=$2
if [ -z "$arg_stack" ] || [ -z "$arg_action" ]; then
    echo "ERROR: Missing required arguments.

Usage: $ bash backup-containers.sh [stack]

Args:
    [action]: The action to be performed. Accepted values: backup | restore
    [stack]: The stack to be backed up/restored. Accepted values: all | [stack_name]"
    exit 1
elif [ "$arg_action" != "backup" ] && [ "$arg_action" != "restore" ]; then
	echo "ERROR: Invalid action"
	exit 1
fi
# Get stacks to backup
parse_config_file $arg_stack
process_stacks $arg_stack

# Retrieve BACKUP_ROOT from .env file
BACKUP_ROOT=$(grep -E "^BACKUP_ROOT" .env | cut -d= -f2 | tr -d ' ')

backup() {
    BACKUP_DIR="$BACKUP_ROOT/$(date +"%Y-%m-%d")"
    [ ! -d $BACKUP_ROOT ] && mkdir -p $BACKUP_ROOT
    [ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR
    echo $(date +"%Y-%m-%d_%H-%M-%S") > $BACKUP_DIR/backup_date.txt

    s=0
    # Backup each stack, with stack specific backup commands
    for stack in "${STACKS[@]}"; do
        echo "INFO: Backing up: $stack"
        if [ ! -d $stack ]; then
            echo "WARNING: Stack $stack does not exist"
            continue
        fi
        cd $stack
        # Create backup directory for stack
        BACKUP_DIR_STACK=$BACKUP_DIR/$stack
        [ ! -d $BACKUP_DIR_STACK ] && mkdir -p $BACKUP_DIR_STACK
        # Stop all containers for the stack
        stop_docker_containers
        # Backup .env, docker-compose.yml and init.sh
        files=(".env" "docker-compose.yml" "init.sh")
        for file in "${files[@]}"; do
            if [ -f $file ]; then
                cp $file $BACKUP_DIR_STACK/$file
            fi
        done
        DIRS_TO_BACKUP=($(get_backup_dirs_by_stack $stack))
        for dir in "${DIRS_TO_BACKUP[@]}"; do
            backup_stack_subdir $dir $BACKUP_DIR_STACK
        done
        # Start all containers for the stack
        start_docker_containers
        cd ..
        s=$((s + 1))
    done

    # Copy contents of scripts directory
    cp -r scripts $BACKUP_DIR/
    # Copy manager.sh, .env file and Makefile
    cp manager.sh $BACKUP_DIR/
    cp .env $BACKUP_DIR/
    cp Makefile $BACKUP_DIR/

    (( $s > 0 )) && echo "INFO: Backed up $s stacks: ${STACKS[@]}" || \
        echo "WARNING: No stacks backed up" 
}

restore (){
    s=0
    # Restore each stack.
    for stack in "${STACKS[@]}"; do
        echo "INFO: Restoring: $stack"
        if [ ! -d $stack ]; then
            echo "WARNING: Stack $stack does not exist"
            continue
        fi

        cd $stack
        DIRS_TO_BACKUP=($(get_backup_dirs_by_stack $stack))
        for dir in "${DIRS_TO_BACKUP[@]}"; do
            restore_stack_subdir $dir
        done
        cd ..
        s=$((s + 1))
    done
    (( $s > 0 )) && echo "INFO: Restored $s stacks: ${STACKS[@]}" || \
        echo "WARNING: No stacks restored"
}

if [ "$arg_action" == "backup" ]; then
    backup
elif [ "$arg_action" == "restore" ]; then
    restore
fi