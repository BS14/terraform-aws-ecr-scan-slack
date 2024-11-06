variable "role_name" {
  description = "Name of the role to be attached to lambda function."
  type        = string
  default     = "lambda-ecr-role"
}

variable "source_file" {
  description = " Package this file into the archive."
  type        = string
  default     = "./functions/ecr_scan_slack.py"
}

variable "output_path" {
  description = "The output of the archive file."
  type        = string
  default     = "./functions/ecr_scan_slack.zip"
}

variable "function_name" {
  description = "unquie name of function."
  type        = string
  default     = "securityNotification"
}

variable "role_arn" {
  description = "Amazon Resource Name (ARN) of the function's execution role."
  type        = string
}

variable "function_description" {
  description = "Describe what does the function does."
  type        = string
  default     = "Used to Send Security Hub and GuardDuty Notification to slack using webhook URL."
}
variable "handler" {
  description = "Function entrypoint in your code."
  type        = string
  default     = "lambda_function.lambda_handler"

}
variable "runtime" {
  description = "Identifier of the function's runtime."
  type        = string
  default     = "python3.12"
}

variable "environment_variables" {
  description = "Map of environment variables that are accessible from the function code during execution"
  type        = map(string)
  default     = {}
}

variable "principal" {
  description = "The principal who is getting this permission"
  type        = string
  default     = "events.amazonaws.com"
}

variable "trigger_source_arn" {
  description = "When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to."
  type        = string
  default     = ""
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 60
}

variable "aws_ssm_parameter_name" {
  description = "Name of the parameter."
  type        = string
  default     = "slack/webhookurl/aws-security"
}

variable "aws_ssm_parameter_description" {
  description = "Description of the parameter."
  type        = string
  default     = "Slack webhook endpoint."
}

variable "type" {
  description = "Type of the parameter."
  type        = string
  default     = "SecureString"
}

variable "ssm_value" {
  description = "Value of the parameter."
  type        = string
}

variable "aws_cloudwatch_event_rule_name" {
  description = "The name of the rule. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = "ecr-scan-slack-notification"
}

variable "aws_cloudwatch_event_rule_description" {
  description = "The description of the rule."
  type        = string
  default     = "Managed by Terraform."
}

variable "schedule_expression" {
  description = "The scheduling expression."
  type        = string
  default     = ""
}

variable "event_pattern" {
  description = "The event pattern described as a JSON object"
  type        = string
  default     = "{\"source\":[\"aws.ecr\"],\"detail-type\":[\"ECR Image Scan\"]}"
}

variable "channel" {
  description = "Enviroment variables for lambda function - Channel to send notification to."
  type        = string
  default     = "aws-security"
}