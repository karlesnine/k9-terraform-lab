resource "aws_s3_bucket" "s3-setting-bucket" {
  bucket = var.s3_bucket_setting_name
  acl    = "private"
  tags = {
    Name = var.s3_bucket_setting_name
    Project = var.your_project_name
  }
}

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("${path.module}/common/s3-files/", "*")

  bucket = aws_s3_bucket.s3-setting-bucket.id
  key    = each.value
  source = "${path.module}/common/s3-files/${each.value}"
  # etag makes the file update when it changes; see https://stackoverflow.com/questions/56107258/terraform-upload-file-to-s3-on-every-apply
  etag   = filemd5("${path.module}/common/s3-files/${each.value}")
}