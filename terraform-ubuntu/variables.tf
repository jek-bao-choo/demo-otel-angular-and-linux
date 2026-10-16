variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_names" {
  description = "Name tags of the EC2 instances to create"
  type        = list(string)
  default     = ["my1", "my2", "cz1"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
  type        = string
  default     = "jek_id_ed25519_pem"
}

variable "storage_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "vpc_name" {
  description = "Name tag of the existing VPC to reuse"
  type        = string
  default     = "jek-vpc"
}

variable "subnet_name" {
  description = "Name tag of the existing public subnet to reuse"
  type        = string
  default     = "jek-public-subnet"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "jek"
}

variable "owner_tag" {
  description = "Owner tag for resources"
  type        = string
  default     = "jek"
}

variable "env_tag" {
  description = "Environment tag for resources"
  type        = string
  default     = "test"
}

variable "ts_creator" {
  description = "ts_creator tag for resources"
  type        = string
  default     = "you@example.com"
}

variable "ts_team" {
  description = "ts_team tag for resources"
  type        = string
  default     = "ese-roa"
}
