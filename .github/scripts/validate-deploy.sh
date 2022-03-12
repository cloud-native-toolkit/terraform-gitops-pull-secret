#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

cat gitops-output.json

COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

SECRET_NAME=$(cat .secret_name)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/secret.yaml" ]]; then
  echo "Application values not found - payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/secret.yaml"
  exit 1
fi

echo "Printing payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/secret.yaml"
cat "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/secret.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi


count=0
until kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for secret/${SECRET_NAME} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for secret/${SECRET_NAME} in ${NAMESPACE}"
  kubectl get secret -n "${NAMESPACE}"
  exit 1
fi

cd ..
rm -rf .testrepo
