# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  default     = "us-east-1"
  description = "AWS region"
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
}

variable "aws_access_key" {
  description = "AWS ACCESS KEY"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS KEY"
  type        = string
}

variable "AWS_SECURITY_TOKEN" {
  description = "AWS SESSION TOKEN"
  type        = string
}