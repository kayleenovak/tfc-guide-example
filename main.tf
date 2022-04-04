provider "aws" {
  region = var.region
}

data "aws_s3_bucket" "example-canaries" {
  bucket = "example-canaries"
}

data "aws_iam_role" "canary-role" {
  name = "canary-role"
}

data "aws_sns_topic" "alert-email" {
  name = "alert-email-topic"
}

module "canary_lambda_zip" {
  source = "./modules/lambda_zip"
  source_dir_path = "canary"
  zip_filename = "canaryLambda.zip"
}

resource "aws_synthetics_canary" "example" {
  name = "example"
  artifact_s3_location = "s3://${data.aws_s3_bucket.example-canaries.id}/"
  execution_role_arn = data.aws_iam_role.canary-role.arn
  runtime_version = "syn-nodejs-puppeteer-3.1"
  handler = "canary.handler"
  zip_file = "${module.canary_lambda_zip.lambda_zip}"
  start_canary = true

  success_retention_period = 1
  failure_retention_period = 1

  schedule {
    expression = "rate(1 hour)"
    duration_in_seconds = 0
  }

  run_config {
    timeout_in_seconds = 300
    memory_in_mb = 960
    active_tracing = false
  }

  tags = {
    Name = "example"
    Environment = "Test"
    Application = "example"
  }
}

resource "aws_cloudwatch_event_rule" "example-canary-event-rule" {
  name = "example-canary-rule"
  event_pattern = jsonencode({
    source = ["aws.synthetics"]
    detail = {
      "canary-name": [aws_synthetics_canary.example.name],
      "test-run-status": ["FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "example-canary-event-target" {
  target_id = "ExampleTarget"
  arn = data.aws_sns_topic.alert-email.arn
  rule = aws_cloudwatch_event_rule.example-canary-event-rule.name
}

# ________________________________________CANARY IAM ROLE___________________________________

data "aws_iam_policy_document" "canary-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "canary-role" {
  name = "canary-role"
  path = "/example/"
  assume_role_policy = data.aws_iam_policy_document.canary-assume-role-policy.json
  description = "IAM role for AWS Synthetic Monitoring Canaries"
}

data "aws_iam_policy_document" "canary-policy" {
  statement {
    sid = "CanaryGeneric"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets",
      "cloudwatch:PutMetricData",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "canary-policy" {
  name = "canary-policy"
  path = "/saints-xctf-com/"
  policy = data.aws_iam_policy_document.canary-policy.json
  description = "IAM role for AWS Synthetic Monitoring Canaries"
}

resource "aws_iam_role_policy_attachment" "canary-policy-attachment" {
  role = aws_iam_role.canary-role.name
  policy_arn = aws_iam_policy.canary-policy.arn
}