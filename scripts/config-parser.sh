#! /bin/bash

# Purpose: Parse a config ini file
# This file contains helper functions to be used by docker compose scripts
# as well as backup and restore scripts

CONF_FILE="scripts/config.ini"
STACKS=()
LINE_NUMS=()
CNAMES=()
BACKUP=()

parse_config_file() {
    local arg_stack=$1
    [ "$arg_stack" == "all" ] && arg_stack=".*?"

    # use grep to find the line number of the stack. each stack is identified by
    # [stack_name] in the config file. we want to extract the stack name and line number
    LINE_NUMS=($(grep -n -E "\[$arg_stack\]" $CONF_FILE | cut -d: -f1))
    STACKS=($(grep -E "\[$arg_stack\]" $CONF_FILE | cut -d[ -f2 | cut -d] -f1))
    # If no stacks found, exit
    if [ -z "$STACKS" ]; then
        echo "ERROR: No stacks found"
        exit 1
    fi
}

process_stacks() {
    local arg_stack=$1
    # For each line number in LINE_NUMS, search the lines between the current
    # line number and the next line number for the string "cname". If found,
    # append the value to CNAMES
    for ((i = 0; i < ${#LINE_NUMS[@]}; i++)); do
        local start_line=${LINE_NUMS[$i]}
        local end_line=${LINE_NUMS[$(($i + 1))]}
        if [ -z "$end_line" ]; then
            # Find next occurence of [*] after start_line
            end_line=$(sed -n "$(($start_line + 1)),$ p" $CONF_FILE | grep -n -m 1 -E "\[.*\]" | cut -d: -f1)
            if [ -z "$end_line" ]; then
                # If no next occurence, then we are at the end of the file
                end_line=$(awk 'END{print NR}' $CONF_FILE)
            else
                # Next occurence found, add start_line to end_line
                end_line=$(($start_line + $end_line - 1))
            fi
        else
            end_line=$(($end_line - 1))
        fi
        # Read the lines between start_line and end_line, grep for "cname", cut
        # the line at the = sign, and get the second field
        local names=$(sed -n "$start_line,$end_line p" $CONF_FILE | grep "cnames" | cut -d= -f2 | tr ',' '\n')
        local backup=($(sed -n "$start_line,$end_line p" $CONF_FILE | grep "backup" | cut -d= -f2 | tr ' ' '\n'))
        CNAMES+=("${names}")
        BACKUP+=("${backup}")
    done
    CNAMES=($(echo ${CNAMES[@]} | tr ' ' '\n'))
}

get_backup_dirs_by_stack() {
    local arg_stack=$1
    # For the provided stack, find the index from LINE_NUMS and use that to
    # find the backup directories
    local index=$(echo ${STACKS[@]} | tr ' ' '\n' | grep -n -m 1 $arg_stack | cut -d: -f1)
    local backup_dirs=${BACKUP[$(($index - 1))]}
    backup_dirs=$(echo $backup_dirs | tr ',' '\n')
    echo $backup_dirs
}

# parse_config_file $1
# process_stacks $1
# for stack in "${STACKS[@]}"; do
#     echo "INFO: Backing up: $stack"
#     backup_dirs=($(get_backup_dirs_by_stack $stack))
#     for dir in "${backup_dirs[@]}"; do
#         echo "INFO: ---Backed up: $dir"
#     done
# done