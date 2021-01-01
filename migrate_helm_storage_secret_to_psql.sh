#!/bin/bash

set -euxo pipefail

HELP="Usage: $0 \
  --db-url DB_URL \
  --db-user DB_USER \
  --db-password DB_PASSWD \
  --db-name DB_NAME \
  --db-schema DB_SCHEMA \
  --db-port DB_PORT"

while [[ $# > 0 ]]
do 
  key="$1" 
  case $key in 
    -h|--help)
      echo $HELP
      exit 0
      ;;
    --db-url)
      DB_URL=$2
      shift
      ;;
    --db-user)
      DB_USER=$2
      shift
      ;;
    --db-password)
      DB_PASSWD=$2
      shift
      ;;
    --db-name)
      DB_NAME=$2
      shift
      ;;
    --db-schema)
      DB_SCHEMA=$2
      shift
      ;;
    --db-port)
      DB_PORT=$2
      shift
      ;;
    *)
      echo "Unknown parameter $1 exiting"
      exit 1
      ;;
  esac
  shift
done

ERROR_MSG="Please set all arguments !"
[[ -z "$DB_URL" ]] && echo $ERROR_MSG && echo $HELP && exit 1
[[ -z "$DB_USER" ]] && echo $ERROR_MSG && echo $HELP && exit 1
[[ -z "$DB_PASSWD" ]] && echo $ERROR_MSG && echo $HELP && exit 1
[[ -z "$DB_NAME" ]] && echo $ERROR_MSG && echo $HELP && exit 1
[[ -z "$DB_SCHEMA" ]] && echo $ERROR_MSG && echo $HELP && exit 1
[[ -z "$DB_PORT" ]] && echo $ERROR_MSG && echo $HELP && exit 1


echo "Asking Kubernetes cluster for Helm secrets"
SRC_DATA=$(kubectl get secrets --all-namespaces -l "owner=helm" -o=jsonpath='{range .items[*]}{.metadata.name}{"#"}{.type}{"#"}{.data.release}{"#"}{.metadata.labels.name}{"#"}{.metadata.namespace}{"#"}{.metadata.labels.version}{"#"}{.metadata.labels.status}{"#"}{.metadata.labels.owner}{"#"}{.metadata.labels.modifiedAt}{"\n"}{end}')
echo "Helm secrets retrieved"

while read -r entry; do
  KEY=$(echo $entry | cut -d '#' -f 1)
  echo "KEY: $KEY"
  TYPE=$(echo $entry | cut -d '#' -f 2)
  echo "TYPE: $TYPE"
  BODY=$(echo $entry | cut -d '#' -f 3 | base64 -d)
  NAME=$(echo $entry | cut -d '#' -f 4)
  echo "NAME: $NAME"
  NAMESPACE=$(echo $entry | cut -d '#' -f 5)
  echo "NAMESPACE: $NAMESPACE"
  VERSION=$(echo $entry | cut -d '#' -f 6)
  echo "VERSION: $VERSION"
  STATUS=$(echo $entry | cut -d '#' -f 7)
  echo "STATUS: $STATUS"
  OWNER=$(echo $entry | cut -d '#' -f 8)
  echo "OWNER: $OWNER"
  MODIFIED=$(echo $entry | cut -d '#' -f 9)
  echo "MODIFIED: $MODIFIED"
  echo ""
  echo "Inserting $KEY into Database"
  export PGPASSWORD=${DB_PASSWD}; echo "INSERT INTO ${DB_SCHEMA}.releases_v1 (key, type, body, name, namespace, version, status, owner, createdat, modifiedat) VALUES ('$KEY', '$TYPE', '$BODY', '$NAME', '$NAMESPACE', '$VERSION', '$STATUS', '$OWNER', $MODIFIED, $MODIFIED);" | psql -h ${DB_URL} -U ${DB_USER} -p ${DB_PORT} -d ${DB_NAME}
done <<< "$SRC_DATA"
