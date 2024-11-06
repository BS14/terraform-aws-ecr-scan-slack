"""
Environment variables:
    CHANNEL: Slack channel name
    SSM_PARAMETER_NAME: Incoming Webhook URL stored in SSM parameter store.
"""

from datetime import datetime
from logging import getLogger, INFO
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import json
import os
import boto3

logger = getLogger()
logger.setLevel(INFO)


def get_properties(finding_counts):
    """Returns the color setting of severity"""
    if finding_counts['CRITICAL'] != 0:
        properties = {'color': 'danger', 'icon': ':red_circle:'}
    elif finding_counts['HIGH'] != 0:
        properties = {'color': 'warning', 'icon': ':large_orange_diamond:'}
    else:
        properties = {'color': 'good', 'icon': ':green_heart:'}
    return properties


def get_params(event):
    """Slack message formatting"""
    region = os.environ['AWS_DEFAULT_REGION']
    channel = os.environ['CHANNEL']
    severity_list = ['CRITICAL', 'HIGH',
                     'MEDIUM', 'LOW', 'INFORMAL', 'UNDEFINED']
    finding_counts = event['detail'].get('finding-severity-counts', {})

    for severity in severity_list:
        finding_counts.setdefault(severity, 0)

    message = f"*ECR Image Scan findings | {region} | Account:{event['account']}*"
    description = "The scan was completed successfully."
    text_properties = get_properties(finding_counts)

    slack_message = {
        'username': 'Amazon ECR',
        'channels': channel,
        'icon_emoji': ':ecr:',
        'text': message,
        'attachments': [
            {
                'fallback': 'AmazonECR Image Scan Findings Description.',
                'color': text_properties['color'],
                'title': f'''{text_properties['icon']} {
                    event['detail']['repository-name']}:{
                    event['detail']['image-tags'][0]}''',
                'title_link': f'''https://{region}.console.aws.amazon.com/ecr/repositories/private/{
                    event['account']}/{event['detail']['repository-name']}/_/image/{
                    event['detail']['image-digest']}/details?region={region}''',
                'text': f'''{description}\n''',
                'fields': [
                    {'title': 'Critical',
                        'value': finding_counts['CRITICAL'], 'short': True},
                    {'title': 'High',
                        'value': finding_counts['HIGH'], 'short': True},
                    {'title': 'Medium',
                        'value': finding_counts['MEDIUM'], 'short': True},
                    {'title': 'Low',
                        'value': finding_counts['LOW'], 'short': True},
                    {'title': 'Informational',
                        'value': finding_counts['INFORMAL'], 'short': True},
                    {'title': 'Undefined',
                        'value': finding_counts['UNDEFINED'], 'short': True},
                ]
            }
        ]
    }
    return slack_message

def lambda_handler(event, context):
    """AWS Lambda Function to send ECR Image Scan Findings to Slack"""
    response = 1

    # Log the event for debugging
    logger.info("Event: %s", json.dumps(event, default=str))
    
    slack_message = get_params(event)

    if not slack_message:
        logger.error("Failed to create Slack message.")
        return response
    
    logger.info("Fetching WEBHOOK_URL stored in parameter store.")

    # Fetch WEBHOOK URL
    ssm = boto3.client('ssm')
    parameter = ssm.get_parameter(
        Name= os.environ['SSM_PARAMETER_NAME'],
        WithDecryption=True
        )
    WEBHOOK_URL = parameter['Parameter']['Value']

    req = Request(WEBHOOK_URL,
                  json.dumps(slack_message).encode('utf-8'))
    try:
        with urlopen(req) as res:
            res.read()
            logger.info("Message posted.")
    except HTTPError as err:
        logger.error("Request failed: %d %s", err.code, err.reason)
    except URLError as err:
        logger.error("Server connection failed: %s", err.reason)
    else:
        response = 0

    return response