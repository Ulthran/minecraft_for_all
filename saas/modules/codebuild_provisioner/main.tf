resource "aws_iam_role" "codebuild" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "terraform" {
  name = "minecraft-codebuild-terraform-policy"
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:*",
        "ec2:*",
        "iam:*",
        "lambda:*",
        "apigateway:*",
        "cloudfront:*",
        "logs:*"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_codebuild_project" "this" {
  name         = var.project_name
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
    environment_variable {
      name  = "REPOSITORY_URL"
      value = var.repository_url
    }
    environment_variable {
      name  = "TENANT_ID"
      value = ""
    }
    environment_variable {
      name  = "SERVER_TYPE"
      value = "papermc"
    }
    environment_variable {
      name  = "INSTANCE_TYPE"
      value = "t4g.medium"
    }
    environment_variable {
      name  = "OVERWORLD_BORDER"
      value = "3000"
    }
    environment_variable {
      name  = "NETHER_BORDER"
      value = "3000"
    }
    environment_variable {
      name  = "STATE_BUCKET"
      value = var.state_bucket_name
    }
    environment_variable {
      name  = "LOCK_TABLE"
      value = var.lock_table_name
    }
    privileged_mode = false
  }
}
