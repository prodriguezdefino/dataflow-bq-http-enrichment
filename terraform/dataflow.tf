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

locals {
  launcher_image_name = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-bq-http-template:latest"
  worker_image_name   = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-bq-http-worker:latest"
}

resource "null_resource" "build_and_push_dataflow_image" {
  triggers = {
    dockerfile_worker = filemd5("${path.module}/../dataflow/Dockerfile.worker")
    pipeline_py = filemd5("${path.module}/../dataflow/pipeline.py")
    http_enrichment_py = filemd5("${path.module}/../dataflow/enrichments/http.py")
    requirements_txt = filemd5("${path.module}/../dataflow/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit \
      --config "${path.module}/../dataflow/cloudbuild.yaml" \
      --substitutions=_LAUNCHER_IMAGE_NAME=${local.launcher_image_name},_WORKER_IMAGE_NAME=${local.worker_image_name} \
      "${path.module}/../dataflow" \
      --quiet
    EOT
  }
}

resource "null_resource" "build_dataflow_template" {
  triggers = {
    dockerfile = filemd5("${path.module}/../dataflow/Dockerfile.template")
    pipeline_py = filemd5("${path.module}/../dataflow/pipeline.py")
    metadata_json = filemd5("${path.module}/../dataflow/metadata.json")
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud dataflow flex-template build gs://${google_storage_bucket.dataflow_template_bucket.name}/flex/dataflow-bq-http-template \
        --image "${local.launcher_image_name}" \
        --sdk-language "PYTHON" \
        --metadata-file "${path.module}/../dataflow/metadata.json" \
        --subnetwork "${google_compute_subnetwork.dataflow_subnetwork.name}"
    EOT
  }
  depends_on = [null_resource.build_and_push_dataflow_image]
}
