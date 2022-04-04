provider "aws" {
  region = var.region
}


# ________________________________________S3 Bucket___________________________________

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "example-canaries" {
  bucket = "example-canaries"
  acl = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 60
    }
  }

  tags = {
    Name = "example-canaries"
    Application = "example-xctf"
    Environment = "all"
  }
}

resource "aws_s3_bucket_policy" "example-canaries-policy" {
  bucket = aws_s3_bucket.example-canaries.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id = "ExampleCanariesPolicy"
    Statement = [
      {
        Sid = "Permissions"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = ["s3:*"]
        Resource = ["${aws_s3_bucket.example-canaries.arn}/*"]
      }
    ]
  })
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

module "canary_lambda_zip" {
  source = "./modules/lambda_zip"
  source_dir_path = "canary"
  zip_filename = "canaryLambda.zip"
}

resource "aws_synthetics_canary" "example" {
  name = "example"
  artifact_s3_location = "s3://${resource.aws_s3_bucket.example-canaries.id}/"
  execution_role_arn = resource.aws_iam_role.canary-role.arn
  runtime_version = "syn-nodejs-puppeteer-3.1"
  handler = "canary.handler"
  zip_file = "./nodejs/node_modules/canaryLambda.zip"
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
