locals {
  s3_base_name = "${var.base_name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket        = local.s3_base_name
  force_destroy = true
  tags          = merge({ "Name" = local.s3_base_name }, var.common_tags)
}

#resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket" {
#  bucket = aws_s3_bucket.my_bucket.id
#
#  rule {
#    apply_server_side_encryption_by_default {
#      kms_master_key_id = aws_kms_key.cmk.arn
#      sse_algorithm     = "aws:kms"
#    }
#  }
#}
