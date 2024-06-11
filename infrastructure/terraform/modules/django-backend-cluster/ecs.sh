#!/bin/bash

## Configure cluster name using the template variable ${ecs_cluster_name}

echo ECS_CLUSTER='ECSCluster_dev' >> /etc/ecs/ecs.config