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

resource "null_resource" "build_and_push_dataflow_image" {
  triggers = {
    dockerfile       = filemd5("${path.module}/../dataflow/Dockerfile")
    pipeline_py      = filemd5("${path.module}/../dataflow/pipeline.py")
    requirements_txt = filemd5("${path.module}/../dataflow/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit --config "${path.module}/../dataflow/cloudbuild.yaml" --substitutions=_IMAGE_NAME=${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-bq-http:latest "${path.module}/../dataflow"
    EOT
  }
}

resource "null_resource" "build_dataflow_template" {
  triggers = {
    dockerfile       = filemd5("${path.module}/../dataflow/Dockerfile")
    pipeline_py      = filemd5("${path.module}/../dataflow/pipeline.py")
    requirements_txt = filemd5("${path.module}/../dataflow/requirements.txt")
    metadata_json    = filemd5("${path.module}/../dataflow/metadata.json")
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud dataflow flex-template build gs://${google_storage_bucket.dataflow_template_bucket.name}/flex/dataflow-bq-http \
        --image "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-bq-http" \
        --sdk-language "PYTHON" \
        --metadata-file "${path.module}/../dataflow/metadata.json" \
        --subnetwork "${google_compute_subnetwork.dataflow_subnetwork.name}"
    EOT
  }
  depends_on = [null_resource.build_and_push_dataflow_image]
}