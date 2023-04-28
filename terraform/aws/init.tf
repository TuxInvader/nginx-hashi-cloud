
provider "aws" {
  region  = var.region
}

provider "time" {
}

resource "aws_vpc" "vpc" {
  tags = {
    Name       = "${var.prefix}-vpc"
  }
  cidr_block = "10.0.0.0/16"
}

resource "random_password" "admin" {
  length = 20
  special = true
  override_special = "_%@"
}

