provider "aws" {
  profile = var.aws_config_profile
  region  = var.aws_region
  version = "~> 2.60"
}

provider "http" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}