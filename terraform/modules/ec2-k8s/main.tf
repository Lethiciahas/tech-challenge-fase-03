data "aws_ami" "ubuntu" {
  most_recent = false
  owners      = ["099720109477"]

  filter {
    name   = "image-id"
    values = ["ami-04680790a315cd58d"]
  }
}

resource "aws_security_group" "k8s_node" {
  name        = "${var.project_name}-${var.environment}-k8s-node-sg"
  description = "Security group for K8s node"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8001
    to_port     = 8005
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30090
    to_port     = 30090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-k8s-node-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "rds_from_k8s" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k8s_node.id
  security_group_id        = var.rds_security_group_id
}

resource "aws_security_group_rule" "redis_from_k8s" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k8s_node.id
  security_group_id        = var.redis_security_group_id
}

resource "aws_iam_role" "k8s_node" {
  name = "${var.project_name}-${var.environment}-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-k8s-node-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "k8s_node_policy" {
  name = "${var.project_name}-${var.environment}-k8s-node-policy"
  role = aws_iam_role.k8s_node.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.project_name}-${var.environment}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "arn:aws:sqs:*:*:${var.project_name}-${var.environment}-*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}-${var.environment}-*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k8s_node" {
  name = "${var.project_name}-${var.environment}-k8s-node-profile"
  role = aws_iam_role.k8s_node.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-k8s-node-profile"
    Environment = var.environment
  }
}

resource "aws_instance" "k8s_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_node.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_node.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    environment  = var.environment
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-k8s-node"
    Environment = var.environment
    Role        = "k8s-node"
  }
}

resource "aws_eip" "k8s_node" {
  instance = aws_instance.k8s_node.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-k8s-node-eip"
    Environment = var.environment
  }
}
