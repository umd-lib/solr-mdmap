# solr-mdmap

## Introduction

Solr core for the Maryland Maps metadata collection

When making updates to the data or configuration, a new Docker image should be
created.

## Building the Docker Image

When building the Docker image, the "data.csv" file will be used to populate the Solr database.

To build the Docker image named "solr-mdmap":

```bash
> docker build -t solr-mdmap .
```

To run the freshly built Docker container on port 8983:

```bash
> docker run -it --rm -p 8983:8983 solr-mdmap
```

To build for deployment:

```bash
> docker buildx build . --builder=kube -t docker.lib.umd.edu/solr-mdmap:VERSION --push
```

## License

See the [LICENSE](LICENSE.txt) file for license rights and limitations.
