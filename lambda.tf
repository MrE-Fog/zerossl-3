data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./fn/dist/"
  output_path = "artifact/${var.project_name}-upload-ssl-cert-to-s3-fn.zip"
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Principal": {
        "Service": ["lambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda" {
  name        = "${var.project_name}_role_policy"
  path        = "/"
  description = "IAM policy for ${var.project_name} lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
        ],
        "Resource" : "arn:aws:s3:::${var.bucket}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-upload-ssl-cert-to-s3-fn"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  filename      = data.archive_file.lambda.output_path
}
