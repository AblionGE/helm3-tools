# helm3-tools

Tools for playing with Helm3

## Migrate Helm backend from Secrets to SQL
### Prerequisites

* Run the script from a machine where you have access to the database you target
* Postgres server is created
* Postgres database is created
* Postgres user is created and owns the database
* kubectl is installed on your machine and configured to access to targeted cluster
* Your kubectl command can access all the secrets from all namespaces

### What it does

* Get all helm secrets from all namespaces using kubectl and and format them with `#` between all required fields
* Loop over all entries and run a SQL query to add the secrets within the Postgresql database

### How to run
```
./migrate_helm_storage_secret_to_psql.sh --db-url DB_URL --db-user DB_USER --db-password DB_PASSWD --db-name DB_NAME --db-schema DB_SCHEMA --db-port DB_PORT
```

### How to use the SQL database with Helm
*WARNING*: it doesn`t use sslmode in this command
```
export HELM_DRIVER=sql
export HELM_DRIVER_SQL_CONNECTION_STRING="postgresql://${DB_URL}:${DB_PORT}/${DB_NAME}?user=${DB_USER}&password=${DB_PASSWORD}&sslmode=disable"
helm list --all-namespaces
```
