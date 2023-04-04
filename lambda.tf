data "archive_file" "lambda" {
  depends_on = [
    null_resource.run_yarn_tsc,
  ]

  type        = "zip"
  source_dir  = "${path.module}/fn/dist/"
  output_path = "${path.module}/artifact/${var.project_name}-upload-ssl-cert-to-s3-fn.zip"
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
  function_name    = "${var.project_name}-upload-ssl-cert-to-s3-fn"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs16.x"
  filename         = data.archive_file.lambda.output_path
  timeout          = 30
  memory_size      = 128
  source_code_hash = data.archive_file.lambda.output_base64sha256
}
