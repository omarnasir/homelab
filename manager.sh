#! /bin/bash

# Manager script to call other scripts inside scripts directory
# Usage: $ bash manager.sh [action] [args]
# Args:
#   [action]: The action to be performed. Accepted values: install | update | backup | restore
#   [stack]: Stacks to be passed to the action script. Accepted values: [stack] | all

action=$1
stack=$2

if [ -z "$action" ] || [ -z "$stack" ]; then
    echo "ERROR: Missing required arguments.

Usage: $ bash manager.sh [action] [stack]

Args:
    [action]: The action to be performed. Accepted values: install | update | backup | restore
    [stack]: Arguments to be passed to the action script. Accepted values: [stack] | all"
    exit 1
fi

# Run the action script
if [ "$action" == "install" ]; then
    bash scripts/install.sh "install" $stack
elif [ "$action" == "update" ]; then
    bash scripts/install.sh "update" $stack
elif [ "$action" == "backup" ]; then
    bash scripts/backup.sh "backup" $stack
elif [ "$action" == "restore" ]; then
    bash scripts/backup.sh "restore" $stack
else
    echo "ERROR: Invalid action"
    exit 1
fi