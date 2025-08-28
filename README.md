# Dataflow BigQuery to HTTP to BigQuery Pipeline

This project demonstrates a data processing pipeline on Google Cloud Platform that reads data from BigQuery, enriches it by calling an HTTP endpoint, and writes the results back to BigQuery.

## Architecture

The solution leverages the following Google Cloud services:

- **BigQuery**: Used as the source and sink for the data.
- **Cloud Run**: Hosts a Python Flask application that acts as an HTTP endpoint, which the Dataflow pipeline calls for data enrichment.
- **Dataflow Flex Template**: Processes data by reading from BigQuery, making HTTP requests to the Cloud Run endpoint, and writing the processed data to another BigQuery table.
- **Cloud Build**: Automates the building and pushing of Docker images for both the Cloud Run application and the Dataflow Flex Template.
- **Terraform**: Manages the infrastructure as code, provisioning all necessary GCP resources (BigQuery datasets/tables, Cloud Run service, Dataflow resources, GCS buckets, Artifact Registry, IAM roles, and network configurations).

The overall data flow is as follows:

1.  **Infrastructure Provisioning**: Terraform sets up all required GCP resources.
2.  **Data Loading**: Sample data is generated and loaded into the BigQuery input table.
3.  **Data Processing**: A Dataflow Flex Template job is triggered. This pipeline reads records from the input BigQuery table, sends each record as a POST request to the Cloud Run HTTP endpoint, and then writes the original data along with the HTTP response to the output BigQuery table.

## Project Structure

```
.
├── .gitignore
├── load_data.sh          # Script to generate and load sample data into BigQuery
├── run_pipeline.sh       # Script to run the Dataflow pipeline
├── run_terraform.sh      # Script to provision infrastructure using Terraform
├── cloud_run/
│   ├── cloudbuild.yaml   # Cloud Build configuration for Cloud Run image
│   └── app/
│       ├── Dockerfile    # Dockerfile for the Cloud Run application
│       └── main.py       # Flask application for the HTTP endpoint
├── dataflow/
│   ├── cloudbuild.yaml   # Cloud Build configuration for Dataflow Flex Template image
│   ├── Dockerfile        # Dockerfile for the Dataflow Flex Template
│   ├── metadata.json     # Metadata for the Dataflow Flex Template
│   ├── pipeline.py       # Dataflow pipeline logic (reads BQ, calls HTTP, writes BQ)
│   └── requirements.txt  # Python dependencies for the Dataflow pipeline
└── terraform/
    ├── bigquery.tf       # BigQuery dataset and table definitions
    ├── cloudrun.tf       # Cloud Run service definition and deployment
    ├── dataflow.tf       # Dataflow Flex Template build and deployment
    ├── iam.tf            # IAM roles and service account for Dataflow
    ├── main.tf           # Terraform provider configuration
    ├── network.tf        # VPC network and subnetwork for Dataflow
    ├── outputs.tf        # Terraform outputs (e.g., table IDs, endpoint URI)
    ├── storage.tf        # GCS bucket for Dataflow templates and Artifact Registry
    └── variables.tf      # Terraform variables
```

## Setup and Deployment

### Prerequisites

*   [Google Cloud SDK (gcloud CLI)](https://cloud.google.com/sdk/docs/install) installed and configured.
*   [Terraform](https://www.terraform.io/downloads.html) installed.
*   A Google Cloud Project with billing enabled.

### 1. Authenticate with Google Cloud

Ensure your `gcloud` CLI is authenticated and configured for your project:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Deploy Infrastructure with Terraform

Navigate to the root of the project and run the Terraform deployment script. This will provision all necessary GCP resources, including BigQuery tables, Cloud Run service, and Dataflow resources.

```bash
./run_terraform.sh
```

Follow the prompts to confirm the Terraform apply.

### 3. Load Sample Data

Once the BigQuery tables are provisioned, you can load sample data into the input table:

```bash
./load_data.sh
```

### 4. Run the Dataflow Pipeline

Finally, execute the Dataflow pipeline. This will read data from the input BigQuery table, process it via the Cloud Run HTTP endpoint, and write the results to the output BigQuery table.

```bash
./run_pipeline.sh
```

You can monitor the Dataflow job in the Google Cloud Console.

## Cleaning Up

To destroy the deployed Google Cloud resources, navigate to the `terraform` directory and run:

```bash
pushd terraform
terraform destroy
popd
```

Follow the prompts to confirm the destruction of resources.
