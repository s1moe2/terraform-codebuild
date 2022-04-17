terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
  }

  backend "s3" {
    bucket = "acme-tfstate-9743d26c-5c66-4614-8a1f-417f86d2f958"
    key    = "tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_key
}

resource "aws_ecr_repository" "acme_registry" {
  name                 = "acme_server"
  image_tag_mutability = "MUTABLE"
}

resource "aws_iam_role" "acme_builder_role" {
  name = "ACME_Builder_CodeBuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "acme_builder_policy" {
  role = aws_iam_role.acme_builder_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "${aws_ecr_repository.acme_registry.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "acme_server" {
  name          = "acme_server"
  build_timeout = "5"
  service_role  = aws_iam_role.acme_builder_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REGISTRY"
      value = "${aws_ecr_repository.acme_registry.repository_url}"
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = var.dockerhub_user
    }

    environment_variable {
      name  = "DOCKERHUB_PASSWORD"
      value = var.dockerhub_password
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/s1moe2/terraform-codebuild.git"
    git_clone_depth = 1
  }
}

resource "aws_codebuild_webhook" "acme_server_build_webhook" {
  project_name = aws_codebuild_project.acme_server.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "^refs/heads/master$"
    }
  }
}

resource "aws_codebuild_source_credential" "acme_credentials" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_pat
}