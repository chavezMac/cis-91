#! /bin/bash 

if [ -z "$1" -o -z "$2" ]; then 
    echo "usage: $0 <project> <keyfile> [billing-account]"
    exit 1 
fi 

PROJECT="$1" 
KEYFILE="$2"
BILLING_ACCT=${3:-'*'}

if [ -f "$KEYFILE" ]; then 
    echo "ERROR: Key file \"$KEYFILE\" already exists."
    exit 1 
fi 

if [ ! -d $(dirname "$KEYFILE") ]; then 
    echo "ERROR: Can't create a key file in a non-existant directory:" $(dirname "$KEYFILE")
    exit 1
fi

BILLING_ID=$(gcloud alpha billing accounts list --format="value(name)" --filter="NAME:$BILLING_ACCT" --limit 1)

if [ -z "$BILLING_ID" ]; then 
    echo "ERROR: No billing account with that name (or there are no billing accounts defined)"
    exit -1 
fi

echo "NOTE: Using billing account: $BILLING_ID"

gcloud projects create --name="${PROJECT}" --set-as-default
PROJECT_ID=$(gcloud config get-value core/project 2>/dev/null)

gcloud iam service-accounts create sa-infra-user \
    --description="Service account to be used by terraform and ansible." \
    --display-name="sa-infra-user"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:sa-infra-user@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/owner"

gcloud iam service-accounts keys create ${KEYFILE} \
    --iam-account="sa-infra-user@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud beta billing projects link ${PROJECT_ID} --billing-account $BILLING_ID

gcloud services enable compute.googleapis.com
