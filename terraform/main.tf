resource "aws_s3_bucket" "backup" {
  bucket = var.backup_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "backup"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft_sg"
  description = "Allow SSH and Minecraft"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25575
    to_port     = 25575
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "minecraft" {
  vpc = true
}

resource "aws_iam_role" "minecraft" {
  name = "minecraft-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  inline_policy {
    name = "s3-backup"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.backup_bucket_name}/*"
      }]
    })
  }
}

resource "aws_iam_instance_profile" "minecraft" {
  name = "minecraft-instance-profile"
  role = aws_iam_role.minecraft.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "minecraft" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t4g.medium"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.minecraft.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    BACKUP_BUCKET = var.backup_bucket_name
  })
}

resource "aws_eip_association" "minecraft" {
  instance_id   = aws_instance.minecraft.id
  allocation_id = aws_eip.minecraft.id
}

resource "aws_iam_role" "lambda" {
  name = "start-minecraft-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  inline_policy {
    name = "start-instance"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["ec2:StartInstances"]
        Resource = aws_instance.minecraft.arn
      }]
    })
  }
}

resource "aws_lambda_function" "start_minecraft" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  function_name    = "start-minecraft"
  role             = aws_iam_role.lambda.arn
  handler          = "start_minecraft.handler"
  runtime          = "python3.11"
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.minecraft.id
    }
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/start_minecraft.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_minecraft.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.start.execution_arn
}

resource "aws_api_gateway_rest_api" "start" {
  name = "start-minecraft-api"
}

resource "aws_api_gateway_resource" "start" {
  rest_api_id = aws_api_gateway_rest_api.start.id
  parent_id   = aws_api_gateway_rest_api.start.root_resource_id
  path_part   = "start"
}

resource "aws_api_gateway_method" "start" {
  rest_api_id   = aws_api_gateway_rest_api.start.id
  resource_id   = aws_api_gateway_resource.start.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start" {
  rest_api_id             = aws_api_gateway_rest_api.start.id
  resource_id             = aws_api_gateway_resource.start.id
  http_method             = aws_api_gateway_method.start.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.start_minecraft.invoke_arn
}

resource "aws_api_gateway_deployment" "start" {
  depends_on  = [aws_api_gateway_integration.start]
  rest_api_id = aws_api_gateway_rest_api.start.id
  stage_name  = "prod"
}

output "minecraft_server_ip" {
  value = aws_eip.minecraft.public_ip
}

output "backup_bucket" {
  value = aws_s3_bucket.backup.bucket
}

output "start_minecraft_api_url" {
  value = aws_api_gateway_deployment.start.invoke_url
}
