# Terraform Karlesnine mini lab

![Terraform CI](https://github.com/karlesnine/terraform-k9-lab/workflows/Terraform%20CI/badge.svg)

Small terraform project to quickly create a lab of three servers on AWS with the default VPC.

## Requirement
- Terraform v0.12.24
  - provider.aws v2.65.0
  - provider.http v1.2.0
  - provider.null v2.1.2
  - provider.template v2.1.2
- aws-cli/1.18.47 

## Use it
- clone this
- Modify `variable.tf` with your own  information
- Configure localy aws cli