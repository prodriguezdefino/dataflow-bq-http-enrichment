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

resource "google_service_account" "dataflow_runner" {
  account_id   = "dataflow-bq-http-sa"
  display_name = "Dataflow BQ HTTP Runner"
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_bigquery_table_iam_member" "input_table_reader" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.bq_dataset.dataset_id
  table_id   = google_bigquery_table.input_table.table_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

resource "google_bigquery_table_iam_member" "output_table_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.bq_dataset.dataset_id
  table_id   = google_bigquery_table.output_table.table_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.dataflow_runner.email}"
}

output "dataflow_runner_email" {
  value = google_service_account.dataflow_runner.email
}