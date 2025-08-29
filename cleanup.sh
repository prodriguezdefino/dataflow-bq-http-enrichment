#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# This script runs the terraform destroy commands to tear down the infrastructure.

# Change into the terraform directory.
pushd infra

# Destroy the terraform configuration.
terraform destroy

popd
