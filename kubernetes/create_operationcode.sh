#!/usr/bin/env bash

# DEPRECATED, ONLY HERE FOR HISTORICAL REFERENCE
# Ask @ohaiwalt for more info

set -euf -o pipefail

# This is a quick hacky script to standup operationcode.org on kubernetes
# If run by itself it will standup all apps. Alternatively you can provide
# it with one or more app names to install

KUBECTL=$(which kubectl)
HELM=$(which helm)

function add_k8s_resources(){
  if [[ -f "deployment.yml" ]]; then $KUBECTL create -f deployment.yml; fi
  if [[ -f "service.yml" ]]; then $KUBECTL create -f service.yml; fi
  if [[ -f "daemonset.yml" ]]; then $KUBECTL create -f daemonset.yml; fi
}

# Create namespace
echo $KUBECTL create -f operationcode-namespace.yml

if [[ $* ]]; then
  apps=$*
else
  apps=$(find . -type d -depth 1)
fi

for app in $apps; do
  app_name=$(basename $app)
  echo "Standing up $app_name"
  cd $app_name

  if [[ -d "secrets" ]]; then
    create_secrets_for $app_name
  fi

  add_k8s_resources

  cd ..
done

exit 0

# Helm is a kubernetes package manager
# You can get a list of apps here: https://kubeapps.com/
$HELM init

## Backend Postgresql
$HELM install --name operationcode-psql stable/postgresql --set postgresPassword=$POSTGRES_PASSWORD

## Backend Redis
$HELM install --name operationcode-redis stable/redis --version 0.10.2 --set usePassword=false
$HELM install --name operationcode-staging-redis --namespace operationcode-staging stable/redis --version 0.10.2 --set usePassword=false
