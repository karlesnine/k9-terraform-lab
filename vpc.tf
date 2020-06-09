data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["Default VPC"]
  }
}