#! /bin/bash
# Create directory config structure if it doesn't exist
LIST_DIRS=( 
    "./grafana" 
    "./grafana/config" 
    "./grafana/config/provisioning" 
    "./grafana/config/provisioning/datasources" 
    "./grafana/config/provisioning/dashboards" 
    "./grafana/config/provisioning/notifiers" 
    "./grafana/config/provisioning/plugins" 
    "./grafana/config/provisioning/alerting"
    "./grafana/data" 
)
for dir in "${LIST_DIRS[@]}"
do
    [ ! -d "$dir" ] && mkdir -p $dir && echo "Created directory $dir" \
        || echo "Directory $dir already exists";
done

# Create config files
[ ! -f "./grafana/config/grafana.ini" ] && touch ./grafana/config/grafana.ini \
    && echo "Created file ./grafana/config/grafana.ini" \
    || echo "File ./grafana/config/grafana.ini already exists";
