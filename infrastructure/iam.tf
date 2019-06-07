data "aws_iam_policy_document" "build_assume" {
  statement {
    sid     = "AllowCodeBuildToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "build" {
  statement {
    sid    = "AllowAccessToBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.snapshot_bucket}",
      "arn:aws:s3:::${var.snapshot_bucket}/*",
    ]
  }

  statement {
    sid    = "AllowPushingLogsToCW"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [aws_cloudwatch_log_group.build.arn]
  }
}

resource "aws_iam_role" "build" {
  name               = "es-build-verification"
  assume_role_policy = data.aws_iam_policy_document.build_assume.json
}

resource "aws_iam_policy" "build" {
  name   = "es-build-verifications"
  policy = data.aws_iam_policy_document.build.json
}

resource "aws_iam_role_policy_attachment" "build" {
  role       = aws_iam_role.build.id
  policy_arn = aws_iam_policy.build.arn
}

data "aws_iam_policy_document" "trigger_assume" {
  statement {
    sid     = "AllowLambdaToAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "trigger" {
  statement {
    sid       = "AllowStartingCodeBuildJob"
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.build.arn]
  }

  statement {
    sid    = "AllowPushingLogsToCW"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [aws_cloudwatch_log_group.trigger.arn]
  }
}

resource "aws_iam_policy" "trigger" {
  name   = "es-build-verifications-trigger"
  policy = data.aws_iam_policy_document.trigger.json
}

resource "aws_iam_role" "trigger" {
  name               = "es-build-verifications-trigger"
  assume_role_policy = data.aws_iam_policy_document.trigger_assume.json
}

resource "aws_iam_role_policy_attachment" "trigger" {
  role       = aws_iam_role.trigger.id
  policy_arn = aws_iam_policy.trigger.arn
}
