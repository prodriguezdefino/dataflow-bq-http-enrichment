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

# Exit immediately if a command exits with a non-zero status.
set -e

# This script generates some sample data and loads it into the input BigQuery table.

# Get the project ID from the gcloud config.
PROJECT_ID="$(terraform -chdir=infra output -raw project_id)"

# Get the input table ID from the terraform output.
INPUT_TABLE_ID="$(terraform -chdir=infra output -raw input_table_id)"

# Set the number of records to generate.
NUM_RECORDS=1000

# Generate a JSON file with some sample data.
DATA_FILE="/tmp/data.json"
rm -f "${DATA_FILE}"
for i in $(seq 1 ${NUM_RECORDS})
do
  echo "{\"id\": ${i}, \"data\": \"record-${i}\"}" >> "${DATA_FILE}"
done

# Load the data into the input BigQuery table.
bq load --source_format=NEWLINE_DELIMITED_JSON "${INPUT_TABLE_ID}" "${DATA_FILE}"
