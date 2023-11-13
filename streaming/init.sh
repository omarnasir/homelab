#! /bin/bash
# Create directory config structure if it doesn't exist
LIST_DIRS=( 
    "./config" 
    "./config/jellyfin" 
)
for dir in "${LIST_DIRS[@]}"
do
    [ ! -d "$dir" ] && mkdir -p $dir && echo "Created directory $dir" \
        || echo "Directory $dir already exists";
done
