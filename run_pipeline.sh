# Copyright (C) 2025 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

#!/bin/bash

# This script requires the gcloud CLI to be installed and configured.

# Get the project ID from the terraform config.
PROJECT_ID=$(terraform -chdir=infra output -raw project_id)

# Get the region from the terraform output.
REGION=$(terraform -chdir=infra output -raw region)

# Get the input table ID from the terraform output.
INPUT_TABLE_ID=$(terraform -chdir=infra output -raw input_table_id)

# Get the output table ID from the terraform output.
OUTPUT_TABLE_ID=$(terraform -chdir=infra output -raw output_table_id)

# Get the HTTP endpoint URL from the terraform output.
HTTP_ENDPOINT=$(terraform -chdir=infra output -raw http_endpoint_uri)

# Get the service account email from the terraform output.
SERVICE_ACCOUNT_EMAIL=$(terraform -chdir=infra output -raw dataflow_runner_email)

# Get the subnetwork from the terraform output.
SUBNETWORK=$(terraform -chdir=infra output -raw dataflow_subnetwork)

# Get the GCS bucket for the dataflow template from the terraform output.
TEMPLATE_GCS_BUCKET=$(terraform -chdir=infra output -raw pipeline_template_bucket)

# Get the custom worker image from the terraform output.
WORKER_IMAGE=$(terraform -chdir=infra output -raw dataflow_worker_image)

# Set the job name.
JOB_NAME="dataflow-bq-http-$(date +%Y%m%d-%H%M%S)"

# Run the dataflow flex template job.
gcloud dataflow flex-template run ${JOB_NAME} \
    --project=${PROJECT_ID} \
    --region=${REGION} \
    --template-file-gcs-location="gs://${TEMPLATE_GCS_BUCKET}/flex/dataflow-bq-http-template" \
    --parameters "input_table=${INPUT_TABLE_ID}" \
    --parameters "output_table=${OUTPUT_TABLE_ID}" \
    --parameters "http_endpoint=${HTTP_ENDPOINT}" \
    --parameters "sdk_container_image=${WORKER_IMAGE}" \
    --parameters "write_method"=STORAGE_WRITE_API \
    --service-account-email=${SERVICE_ACCOUNT_EMAIL} \
    --subnetwork=${SUBNETWORK} \
    --staging-location="gs://${TEMPLATE_GCS_BUCKET}/staging" \
    --worker-machine-type=n2d-standard-4
