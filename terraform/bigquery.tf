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

resource "google_bigquery_dataset" "bq_dataset" {
  dataset_id = "dataflow_http_process"
  location   = var.region
}

resource "google_bigquery_table" "input_table" {
  dataset_id = google_bigquery_dataset.bq_dataset.dataset_id
  table_id   = "input_table"
  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}

resource "google_bigquery_table" "output_table" {
  dataset_id = google_bigquery_dataset.bq_dataset.dataset_id
  table_id   = "output_table"
  schema = <<EOF
[
  {
    "name": "id",
    "type": "INTEGER",
    "mode": "REQUIRED"
  },
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "http_response",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}