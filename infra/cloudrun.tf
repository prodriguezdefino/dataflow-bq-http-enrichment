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

resource "null_resource" "build_and_push_cloud_run_image" {
  triggers = {
    dockerfile      = filemd5("${path.module}/../cloud_run/app/Dockerfile")
    main_py         = filemd5("${path.module}/../cloud_run/app/main.py")
    cloudbuild_yaml = filemd5("${path.module}/../cloud_run/cloudbuild.yaml")
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud builds submit \
      --config "${path.module}/../cloud_run/cloudbuild.yaml" \
      --substitutions=_IMAGE_NAME=${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-http-app:latest \
      "${path.module}/../cloud_run/app" \
      --quiet
    EOT
  }
}

resource "google_cloud_run_v2_service" "http_endpoint" {
  name     = "dataflow-bq-http-endpoint"
  location = var.region

  deletion_protection = false

  template {
    # Add annotations to force a new revision when code changes
    annotations = {
      "app-code-version-src"    = null_resource.build_and_push_cloud_run_image.triggers.main_py
      "app-code-version-docker" = null_resource.build_and_push_cloud_run_image.triggers.dockerfile
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}/dataflow-http-app:latest"
    }
  }
  depends_on = [null_resource.build_and_push_cloud_run_image]
}

resource "google_cloud_run_service_iam_member" "allow_public" {
  location = google_cloud_run_v2_service.http_endpoint.location
  service  = google_cloud_run_v2_service.http_endpoint.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}