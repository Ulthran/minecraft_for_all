
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_subnet" "public" {
  id = data.aws_subnets.public.ids[0]
}

resource "aws_vpc_ipv6_cidr_block_association" "default" {
  count                            = data.aws_vpc.default.ipv6_association_id == "" ? 1 : 0
  vpc_id                           = data.aws_vpc.default.id
  assign_generated_ipv6_cidr_block = true
}

locals {
  vpc_ipv6_cidr_block = data.aws_vpc.default.ipv6_cidr_block != "" ? data.aws_vpc.default.ipv6_cidr_block : (length(aws_vpc_ipv6_cidr_block_association.default) > 0 ? aws_vpc_ipv6_cidr_block_association.default[0].ipv6_cidr_block : null)
}

resource "null_resource" "associate_subnet_ipv6" {
  count = data.aws_subnet.public.ipv6_cidr_block == "" ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 associate-subnet-cidr-block --subnet-id ${data.aws_subnet.public.id} --ipv6-cidr-block ${cidrsubnet(local.vpc_ipv6_cidr_block, 8, 0)}"
  }

  depends_on = [aws_vpc_ipv6_cidr_block_association.default]
}

resource "tls_private_key" "tenant" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tenant" {
  key_name   = "${var.tenant_id}-key"
  public_key = tls_private_key.tenant.public_key_openssh
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-${var.tenant_id}-sg"
  description = "Allow SSH and Minecraft"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 25565
    to_port          = 25565
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 25575
    to_port     = 25575
    protocol    = "tcp"
    cidr_blocks = ["127.0.0.1/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "minecraft" {
  name = "minecraft-${var.tenant_id}-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "minecraft_backup" {
  name = "minecraft-${var.tenant_id}-s3-backup"
  role = aws_iam_role.minecraft.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${var.backup_bucket_name}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "minecraft" {
  name = "minecraft-${var.tenant_id}-instance-profile"
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
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  key_name               = aws_key_pair.tenant.key_name
  iam_instance_profile   = aws_iam_instance_profile.minecraft.name
  ipv6_address_count     = 1

  tags = local.common_tags

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    tags        = local.common_tags
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    BACKUP_BUCKET    = var.backup_bucket_name,
    TENANT_ID        = var.tenant_id,
    SERVER_TYPE      = var.server_type,
    OVERWORLD_RADIUS = var.overworld_border_radius,
    NETHER_RADIUS    = var.nether_border_radius
  })
}

output "minecraft_server_ip" {
  value = aws_instance.minecraft.ipv6_addresses[0]
}

output "backup_bucket" {
  value = var.backup_bucket_name
}

output "key_pair_private_key" {
  value     = tls_private_key.tenant.private_key_pem
  sensitive = true
}

