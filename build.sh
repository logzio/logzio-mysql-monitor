#!/bin/bash

export TAG="logzio/mysql-monitor:latest"

docker build -t $TAG ./

echo "Built: $TAG"
