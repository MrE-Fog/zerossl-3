resource "aws_iam_role" "eventbridge" {
  name               = "${var.project_name}-eventbridge-role"
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

resource "aws_iam_policy" "eventbridge" {
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

resource "aws_iam_role_policy_attachment" "eventbridge" {
  role       = aws_iam_role.eventbridge.name
  policy_arn = aws_iam_policy.eventbridge.arn
}

resource "aws_scheduler_schedule" "eventbridge" {
  depends_on = [
    aws_lambda_function.main,
  ]

  name        = "${var.project_name}-upload-ssl-cert-to-s3-schedule"
  description = "Upload new SSL cert to S3 every 2 months"
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "cron(0 0 1 1/2 ? *)"
  target {
    arn      = aws_lambda_function.main.arn
    role_arn = aws_iam_policy.eventbridge.arn
  }
}
