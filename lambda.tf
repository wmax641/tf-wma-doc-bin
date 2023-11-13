data "archive_file" "getfile" {
  type             = "zip"
  source_file      = "${path.module}/files/getfile.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/getfile.py.zip"
}

resource "aws_lambda_function" "getfile" {
  filename         = data.archive_file.getfile.output_path
  function_name    = "${var.base_name}-getfile"
  role             = aws_iam_role.getfile_lambda.arn
  handler          = "getfile.lambda_handler"
  timeout          = var.lambda_timeout
  source_code_hash = filebase64sha256(data.archive_file.getfile.output_path)
  runtime          = var.lambda_python_runtime
  environment {
    variables = {
      S3_BUCKET      = aws_s3_bucket.my_bucket.id
      DYNAMODB_TABLE = aws_dynamodb_table.dynamodb_table.id
    }
  }
  tags = merge({ "Name" = "${var.base_name}-getfile" }, var.common_tags)
}

resource "aws_iam_role" "getfile_lambda" {
  name = "${var.base_name}-getfile_lambda_role"
  path = "/service/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  #managed_policy_arns = [
  #  aws_iam_policy.getfile_lambda.arn,
  #]

  tags = merge({ "Name" = var.base_name }, var.common_tags)
}

resource "aws_iam_policy_attachment" "getfile_lambda_attachment" {
  name       = "getfile_lambda_attachment"
  roles      = [aws_iam_role.getfile_lambda.name]
  policy_arn = aws_iam_policy.getfile_lambda.arn
}

resource "aws_iam_policy" "getfile_lambda" {
  name   = "${var.base_name}-getfile-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.getfile_lambda.json
}

data "aws_iam_policy_document" "getfile_lambda" {
  statement {
    sid     = "ReadS3"
    actions = ["s3:getObject"]
    resources = [
      "${aws_s3_bucket.my_bucket.arn}/*",
    ]
  }
  statement {
    sid = "ReadDynamoDB"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
    ]
    resources = [
      "${aws_dynamodb_table.dynamodb_table.arn}"
    ]
  }
  statement {
    actions = ["logs:CreateLogGroup"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:ap-southeast-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.base_name}*"
    ]
  }

}


