#!/usr/bin/env bash

set -uexo pipefail

terraform plan -out terraform.tfplan
