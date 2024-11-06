data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "notify-ecr-scan-results_lambda-ROLE" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambdaBasicExecutionPolicy-aws_iam_role_policy_attachment" {
  role       = aws_iam_role.notify-ecr-scan-results_lambda-ROLE.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional policy to retreive secrets from SSM Paramter Store

resource "aws_iam_policy" "additional_policy" {
  #name = "SSM-Parameter-fetch-POLICY"
  path   = "/"
  policy = <<EOF
    {
     "Version": "2012-10-17",
     "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/slack/webhookurl/aws-security"]
        }
     ]
}
    EOF
}
resource "aws_iam_role_policy_attachment" "notify-ecr-scan-results_lambda-ROLE-POLICY-attach" {
  role       = aws_iam_role.notify-ecr-scan-results_lambda-ROLE.name
  policy_arn = aws_iam_policy.additional_policy.arn
}

resource "aws_lambda_function" "ecr-scan-lambda" {
  function_name = var.function_name
  filename      = var.output_path
  description   = var.function_description
  role          = aws_iam_role.notify-ecr-scan-results_lambda-ROLE.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  environment = {
    CHANNEL            = var.channel,
    SSM_PARAMETER_NAME = var.aws_ssm_parameter_name
  }
}

resource "aws_lambda_permission" "with_eb" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecr-scan-lambda.arn
  principal     = var.principal
  source_arn    = var.trigger_source_arn
}

resource "aws_ssm_parameter" "slack_webhook" {
  name        = var.aws_ssm_parameter_name
  description = var.aws_ssm_paramter_description
  type        = var.type
  value       = var.ssm_value
}

resource "aws_cloudwatch_event_rule" "console" {
  name                = var.aws_cloudwatch_event_rule_name
  description         = var.aws_cloudwatch_event_rule_description
  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule = aws_cloudwatch_event_rule.console.name
  arn  = aws_lambda_function.ecr-scan-lambda.arn
}