#!/usr/bin/env bash

set -uexo pipefail

terraform apply terraform.tfplan
