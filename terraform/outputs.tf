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

output "region" {
  value = var.region
}

output "input_table_id" {
  value = "${google_bigquery_table.input_table.project}:${google_bigquery_table.input_table.dataset_id}.${google_bigquery_table.input_table.table_id}"
}

output "output_table_id" {
  value = "${google_bigquery_table.output_table.project}:${google_bigquery_table.output_table.dataset_id}.${google_bigquery_table.output_table.table_id}"
}

output "http_endpoint_uri" {
  value = google_cloud_run_v2_service.http_endpoint.uri
}

output "docker_repo_id" {
  value = google_artifact_registry_repository.docker_repo.repository_id
}

output "cloud_run_service_name" {
  value = google_cloud_run_v2_service.http_endpoint.name
}

output "dataflow_subnetwork" {
  value = google_compute_subnetwork.dataflow_subnetwork.self_link
}

output "pipeline_template_bucket" {
  value = google_storage_bucket.dataflow_template_bucket.name
}

output "dataflow_worker_image" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-bq-http-worker:latest"
}
