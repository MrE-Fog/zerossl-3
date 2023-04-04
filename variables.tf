variable "project_name" {
  type        = string
  description = "The name of the project"
}

variable "region" {
  type        = string
  description = "The AWS region to deploy to"
}

variable "environment" {
  type        = string
  description = "The environment to deploy to"
}

variable "owner" {
  type        = string
  description = "The owner of the project"
}

variable "bucket" {
  type        = string
  description = "The name of the bucket"
}
