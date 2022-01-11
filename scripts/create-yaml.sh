#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)

NAME="$1"
NAMESPACE="$2"
DEST_DIR="$3"

mkdir -p "${DEST_DIR}"

kubectl create secret docker-registry \
  "${NAME}" \
  -n "${NAMESPACE}" \
  --docker-server="${SERVER}" \
  --docker-username="${USERNAME}" \
  --docker-password="${PASSWORD}" \
  --dry-run=client \
  -o yaml \
  > "${DEST_DIR}/secret.yaml"
