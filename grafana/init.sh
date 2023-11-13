#! /bin/bash
# Create directory config structure if it doesn't exist
LIST_DIRS=( 
    "./config" 
    "./config/provisioning" 
    "./config/provisioning/datasources" 
    "./config/provisioning/dashboards" 
    "./config/provisioning/notifiers" 
    "./config/provisioning/plugins" 
    "./config/provisioning/alerting"
    "./data"
)
for dir in "${LIST_DIRS[@]}"
do
    [ ! -d "$dir" ] && mkdir -p $dir && echo "Created directory $dir" \
        || echo "Directory $dir already exists";
done

# Create config files
[ ! -f "./config/grafana.ini" ] && touch ./config/grafana.ini \
    && echo "Created file ./config/grafana.ini" \
    || echo "File ./config/grafana.ini already exists";
