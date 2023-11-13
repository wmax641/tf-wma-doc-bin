resource "aws_dynamodb_table" "dynamodb_table" {
  name         = var.base_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = merge({ "Name" = var.base_name }, var.common_tags)
}
