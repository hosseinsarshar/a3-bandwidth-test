# Nemo on Vertex

This repo helps to run the benchmarking script of Nemo on Vertex AI for distributed training.

To start:

## Build a docker image

You can either fetch the docker file from classicboyir/nemo:02 on dockerhub or build the image with [docker/nemo_example.Dockerfile](docker/nemo_example.Dockerfile).

```

```

How to mount storage:

gcloud container clusters update $CLUSTER_NAME \
    --location=$LOCATION \
    --workload-pool=$PROJECT_ID.svc.id.goog

```
gcloud container clusters update $CLUSTER_NAME \
    --update-addons GcsFuseCsiDriver=ENABLED \
    --location=$LOCATION
```