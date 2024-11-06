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