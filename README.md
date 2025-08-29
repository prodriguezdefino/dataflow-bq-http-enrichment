# Dataflow BigQuery to HTTP to BigQuery Pipeline

This project demonstrates a data processing pipeline on Google Cloud Platform that reads data from BigQuery, enriches it by calling an HTTP endpoint, and writes the results back to BigQuery.

## Architecture

The solution leverages the following Google Cloud services:

- **BigQuery**: Used as the source and sink for the data. Reads use the BigQuery Storage Read API for efficiency.
- **Cloud Run**: Hosts a Python Flask application that acts as an HTTP endpoint, which the Dataflow pipeline calls for data enrichment.
- **Dataflow Flex Template**: Processes data by reading from BigQuery, making HTTP requests to the Cloud Run endpoint, and writing the processed data to another BigQuery table.
- **Dataflow Custom Containers**: A custom worker container is used to ensure all pipeline dependencies and custom code are consistently available to Dataflow workers, improving reliability and startup times.
- **Cloud Build**: Automates the building and pushing of Docker images for the Cloud Run application, the Dataflow Flex Template launcher, and the Dataflow custom worker container. A unified Cloud Build configuration streamlines this process.
- **Terraform**: Manages the infrastructure as code, provisioning all necessary GCP resources (BigQuery datasets/tables, Cloud Run service, Dataflow resources, GCS buckets, Artifact Registry, IAM roles, and network configurations).

The overall data flow is as follows:

1.  **Infrastructure Provisioning**: Terraform sets up all required GCP resources.
2.  **Data Loading**: Sample data is generated and loaded into the BigQuery input table.
3.  **Data Processing**: A Dataflow Flex Template job is triggered. This pipeline reads records from the input BigQuery table (using the Storage Read API), sends each record as a POST request to the Cloud Run HTTP endpoint, and then writes the original data along with the HTTP response to the output BigQuery table. The write method (File Loads or Storage Write API) is configurable.

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
│   ├── cloudbuild.yaml   # Unified Cloud Build configuration for Dataflow images
│   ├── Dockerfile.template # Dockerfile for the Dataflow Flex Template launcher image (includes Java 17 JRE)
│   ├── Dockerfile.worker # Dockerfile for the Dataflow custom worker container
│   ├── metadata.json     # Metadata for the Dataflow Flex Template
│   ├── pipeline.py       # Main Dataflow pipeline logic
│   ├── requirements.txt  # Python dependencies for the Dataflow pipeline
│   ├── setup.py          # Python packaging file for the dataflow module and its dependencies
│   └── enrichments/      # Python package containing custom enrichment logic
│       ├── __init__.py
│       └── http.py       # HTTP enrichment handler and join function
└── terraform/
    ├── bigquery.tf       # BigQuery dataset and table definitions
    ├── cloudrun.tf       # Cloud Run service definition and deployment
    ├── dataflow.tf       # Dataflow Flex Template and custom worker image build/deployment
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

Navigate to the root of the project and run the Terraform deployment script. This will provision all necessary GCP resources, including BigQuery tables, Cloud Run service, and Dataflow resources, and build/push the Docker images.

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

Finally, execute the Dataflow pipeline. This will read data from the input BigQuery table, process it via the Cloud Run HTTP endpoint, and write the results to the output BigQuery table. You can configure the BigQuery write method.

```bash
./run_pipeline.sh
```

**Pipeline Parameters:**
*   `input_table`: The BigQuery table to read from.
*   `output_table`: The BigQuery table to write to.
*   `http_endpoint`: The HTTP endpoint to call for enrichment.
*   `sdk_container_image`: The custom SDK container image to use for Dataflow workers (automatically passed by `run_pipeline.sh`).
*   `write_method`: Method to write to BigQuery. Options: `FILE_LOADS` (default) or `STORAGE_WRITE_API`.

You can monitor the Dataflow job in the Google Cloud Console.

## Cleaning Up

To destroy the deployed Google Cloud resources, run the following script:

```bash
./destroy_terraform.sh
```

Follow the prompts to confirm the destruction of resources.