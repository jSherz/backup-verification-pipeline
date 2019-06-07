terraform {
  required_version = "~> 0.12"
}

provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.14"
}

resource "aws_s3_bucket" "snapshots" {
  bucket = var.snapshot_bucket

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "snapshots" {
  bucket = aws_s3_bucket.snapshots.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "script" {
  bucket = aws_s3_bucket.snapshots.bucket
  key    = "verify.py"
  source = "../script/verify.py"
  etag   = filemd5("../script/verify.py")
}

resource "aws_s3_bucket_object" "script_requirements" {
  bucket = aws_s3_bucket.snapshots.bucket
  key    = "requirements.txt"
  source = "../script/requirements.txt"
  etag   = filemd5("../script/requirements.txt")
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.snapshots.bucket

  lambda_function {
    events              = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.trigger.arn
    filter_prefix       = "snap-"
  }
}

resource "aws_lambda_function" "trigger" {
  function_name    = "es-backup-verification"
  handler          = "index.handler"
  role             = aws_iam_role.trigger.arn
  runtime          = "python3.7"
  filename         = "../lambda/function.zip"
  source_code_hash = filebase64sha256("../lambda/function.zip")
  timeout          = 10
  memory_size      = 256
}

resource "aws_lambda_permission" "trigger" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.snapshots.arn
}

resource "aws_cloudwatch_log_group" "trigger" {
  name              = "/aws/lambda/es-backup-verification"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/es-backup-verification"
  retention_in_days = 14
}

resource "aws_codebuild_project" "build" {
  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0-1.10.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "SNAPSHOT_BUCKET"
      value = var.snapshot_bucket
    }

    environment_variable {
      name  = "ES_URL"
      value = "http://localhost:9200"
    }

    environment_variable {
      name  = "ES_REPO"
      value = "verify"
    }

    privileged_mode = true
  }

  name = "es-backup-verification"

  source {
    type      = "NO_SOURCE"
    buildspec = file("buildspec.yml")
  }

  service_role = aws_iam_role.build.arn
}
