# Validate data.csv using csv-validator 1.1.5
# https://digital-preservation.github.io/csv-validator/
FROM docker.lib.umd.edu/csv-validator:1.1.5-umd-0 AS validator

#COPY --from=cleaner /tmp/clean.csv /tmp/clean.csv
COPY data.csv /tmp/data.csv
COPY data.csvs /tmp/data.csvs

RUN validate /tmp/data.csv /tmp/data.csvs

# Load data.csv into the Solr core
FROM solr:8 AS builder
# FROM solr:8.11.0@sha256:f9f6eed52e186f8e8ca0d4b7eae1acdbb94ad382c4d84c8220d78e3020d746c6 AS builder

# Switch to root user
USER root

# Install xmlstarlet
RUN apt-get update -y && \
    apt-get install -y xmlstarlet

# Set the SOLR_HOME directory env variable
ENV SOLR_HOME=/apps/solr/data

# Create the SOLR_HOME directory and set ownership
RUN mkdir -p /apps/solr/ && \
    cp -r /var/solr/data /apps/solr/data && \
    chown -R solr:0 "$SOLR_HOME"

# Switch back to solr user
USER solr

# Create the mdmap core
RUN /opt/solr/bin/solr start && \
    /opt/solr/bin/solr create_core -c mdmap && \
    /opt/solr/bin/solr stop

# Replace the schema file
COPY conf /apps/solr/data/mdmap/conf/

# Add the data to be loaded
COPY --from=validator /tmp/data.csv /tmp/data.csv

# Load the data to mdmap core
# id,path,object_type,rights_statement,title,handle_link,format,archival_collection,notes,railroad,map_type,creator,publisher,region,waterway,cities,counties,regions,states,extent,date,files
# id,object_type,rights_statement,title,handle_link,format,archival_collection,notes,railroad,map_type,creator,publisher,region,waterway,states,regions,counties,cities,extent,display_date,start_date,path,files
RUN /opt/solr/bin/solr start && sleep 3 && \
    curl 'http://localhost:8983/solr/mdmap/update?commit=true' -H 'Content-Type: text/xml' --data-binary '<delete><query>*:*</query></delete>' && \
    curl 'http://localhost:8983/solr/mdmap/update?commit=true&header=true&fieldnames=id,object_type,rights_statement,title,handle_link,format,archival_collection,notes,railroad,map_type,creator,publisher,region,waterway,states,regions,counties,cities,extent,display_date,start_date,path,files&f.states.split=true&f.cities.split=true&f.regions.split=true&f.counties.split=true' \
    # curl 'http://localhost:8983/solr/mdmap/update?commit=true&header=true&fieldnames=id,object_type,rights_statement,title,handle_link,format,archival_collection,description,creator,publisher,location,extent,date,files' \
        --data-binary @/tmp/data.csv -H 'Content-type:application/csv'&& \
    /opt/solr/bin/solr stop

# Create the Solr runtime container
FROM solr:8-slim

ENV SOLR_HOME=/apps/solr/data

USER root
RUN mkdir -p /apps/solr/ && \
    cp -r /var/solr/data /apps/solr/data && \
    chown -R solr:0 "$SOLR_HOME"

USER solr
COPY --from=builder /apps/solr/ /apps/solr/
